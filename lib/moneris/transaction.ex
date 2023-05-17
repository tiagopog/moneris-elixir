defmodule Moneris.Transaction do
  import SweetXml
  alias Moneris.Response

  @moduledoc """
  Transaction.
  """

  def build_card(%{name: name, email: email, phone: phone, pan: pan, expdate: expdate} = card) do
    [
      XmlBuilder.element(:cust_id,  email),
      XmlBuilder.element(:phone,    phone),
      XmlBuilder.element(:email,    email),
      XmlBuilder.element(:note,     name || ""),
      XmlBuilder.element(:pan,      pan),
      XmlBuilder.element(:expdate,  expdate)
    ] ++ build_cvd(card)
  end

  def build_card(%{pan: pan, expdate: expdate} = card) do
    [
      XmlBuilder.element(:pan,     pan),
      XmlBuilder.element(:expdate, expdate)
    ] ++ build_cvd(card)
  end

  def build_card(_) do
    []
  end

  # network tokenization for Apply Pay and Android Pay
  def build_network_tokenization(%{cryptogram: cryptogram, source: source}) do
    wallet_indicator = case source do
      "apple_pay" -> "APP"
      "android_pay" -> "ANP"
      # TODO: Samsung Pay?
    end

    [
      XmlBuilder.element(:cavv, cryptogram),
      XmlBuilder.element(:wallet_indicator, wallet_indicator)
    ]
  end

  def build_verification(expdate, order_id) do
    [
      XmlBuilder.element(:order_id, order_id),
      XmlBuilder.element(:expdate,  expdate)
    ]
  end

  def build_avs(%{zip: zip}) do
    avs_info = [XmlBuilder.element(:avs_zipcode, zip)]

    [XmlBuilder.element(:avs_info, avs_info)]
  end
  def build_avs(_) do
    []
  end

  def build_cvd(%{cvv: cvv}) do
    cvd_info = [
      XmlBuilder.element(:cvd_indicator, 1),
      XmlBuilder.element(:cvd_value, cvv)
    ]

    [XmlBuilder.element(:cvd_info, cvd_info)]
  end

  def build_cvd(_) do
    []
  end

  def default_crypt_type do
    [XmlBuilder.element(:crypt_type,  7)] # 7 = SSL enabled merchant
  end

  def build_refund(order) do
    [
      XmlBuilder.element(:txn_number,  order.transaction_number),
      XmlBuilder.element(:order_id,    order.order_id),
      XmlBuilder.element(:crypt_type,  order.crypt_type)
    ]
  end

  def build_partial_refund(order, refund_amount) do
    refund_in_decimal = (refund_amount / 1) / 100.0

    [
      XmlBuilder.element(:txn_number, order.transaction_number),
      XmlBuilder.element(:order_id,   order.order_id),
      XmlBuilder.element(:crypt_type, order.crypt_type),
      XmlBuilder.element(:amount,     refund_in_decimal)
    ]
  end

  def build_partial_refund_for_vault(order, refund_amount) do
    refund_in_decimal = (refund_amount / 1) / 100.0

    # no txn_number (empty or otherwise) when using vault
    [
      XmlBuilder.element(:order_id,   order.order_id),
      XmlBuilder.element(:crypt_type, order.crypt_type),
      XmlBuilder.element(:amount,     refund_in_decimal)
    ]
  end

  def build_token(token) do
    [XmlBuilder.element(:data_key, token)]
  end

  def build_capture(order) do
    amount_in_decimal = (order.amount / 1) / 100.0

    [
      XmlBuilder.element(:comp_amount,     amount_in_decimal),
      XmlBuilder.element(:txn_number,  order.transaction_number),
      XmlBuilder.element(:order_id,   order.order_id),
      XmlBuilder.element(:crypt_type, order.crypt_type)
    ]
  end

  def build_order(order) do
    amount_in_decimal = (order.amount / 1) / 100.0

    [
      XmlBuilder.element(:amount,     amount_in_decimal),
      XmlBuilder.element(:order_id,   order.order_id),
      XmlBuilder.element(:crypt_type, order.crypt_type),
      XmlBuilder.element(:cust_id,    order.cust_id)
    ]
  end

  def build_response({:ok, %{body: body}}) do
    xml = body |> parse
    # is_complete = xpath(xml, ~x"//response/receipt/Complete/text()"s)
    response_code = xpath(xml, ~x"//response/receipt/ResponseCode/text()"Io) || 999
    success = response_code < 50
    if success do
      {:ok, parse_order_response(xml)}
    else
      {:error, parse_error_reponse(xml)}
    end
  end
  def build_response({:error, %{body: body}}) do
    xml = body |> parse
    {:error, parse_error_reponse(xml)}
  end
  def build_response(_) do
    {:error, %Response{success: false, message: "unable to complete transaction."}}
  end

  defp parse_order_response(xml) do
    order_id = xpath(xml, ~x"//response/receipt/ReceiptId/text()"s)
    transaction_number = xpath(xml, ~x"//response/receipt/TransID/text()"s)
    reference_number = xpath(xml, ~x"//response/receipt/ReferenceNum/text()"s)
    # auth_code = xpath(xml, ~x"//response/receipt/AuthCode/text()"s)
    message = xpath(xml, ~x"//response/receipt/Message/text()"s)
    cvd = xpath(xml, ~x"//response/receipt/CvdResultCode/text()"s)
    avs = xpath(xml, ~x"//response/receipt//AvsResultCode/text()"s)

    response_code = xpath(xml, ~x"//response/receipt/ResponseCode/text()"Io) || 999
    success = response_code < 50

    decimal_amount = xpath(xml, ~x"//response/receipt/TransAmount/text()"s)
    # this converts the text "null" to 0, unlike using the "f" option with xpath:
    decimal_amount = case Float.parse(decimal_amount) do
    {decimal_amount, _} -> decimal_amount
    :error -> 0.0
    end

    amount = round(decimal_amount * 100)

    %Response{
      order_id: order_id,
      transaction_number: transaction_number,
      reference_number: reference_number,
      message: convert_message(message),
      cvd: cvd,
      cvd_verified: cvd_verified?(cvd),
      avs: avs,
      address_verified: address_verified?(avs),
      zipcode_verified: zipcode_verified?(avs),
      success: success,
      amount: amount,
    }
  end

  defp parse_error_reponse(xml) do
    message = xpath(xml, ~x"//response/receipt/Message/text()"s)
    cvd = xpath(xml, ~x"//response/receipt/CvdResultCode/text()"s)
    avs = xpath(xml, ~x"//response/receipt//AvsResultCode/text()"s)

    error_message = cvd_error_message(cvd) || avs_error_message(avs) || convert_message(message)

    # this is typically a two character string "1M" where the second char is the code we need to check.
    cvd = String.at(cvd, 1) || cvd

    %Response{
      message: error_message,
      cvd: cvd,
      cvd_verified: cvd_verified?(cvd),
      avs: avs,
      address_verified: address_verified?(avs),
      zipcode_verified: zipcode_verified?(avs),
      success: false
    }
  end

  defp cvd_error_message(cvd) do
    if cvd == "null" do
      nil
    else
      # this is typically a two character string "1M" where the second char is the code we need to check.
      cvd = String.at(cvd, 1) || cvd

      case verify_cvd(cvd) do
        {:error, message} -> message
        _ -> nil
      end
    end
  end

  defp avs_error_message(avs) do
    if avs == "null" do
      nil
    else
      case verify_zipcode(avs) do
        {:error, message} -> message
        _ -> nil
      end
    end
  end

  def convert_message(message) do
    cond do
      String.starts_with?(message, "DECLINED") -> "Declined"
      String.starts_with?(message, "APPROVED") -> "Approved"
      String.starts_with?(message, "EXPIRED") -> "Card Expired"
      String.starts_with?(message, "CALL FOR") -> "Unable to process transaction"
      true -> message
    end
  end

  def cvd_verified?(cvd) do
    case verify_cvd(cvd) do
      {:ok, _} -> true
      _ -> false
    end
  end

  def verify_cvd(cvd) do
    case cvd do
      "M" -> {:ok, "Match"}
      "Y" -> {:ok, "Match"}
      _ -> {:error, "Unable to verify cvv."}
    end
  end

  def address_verified?(avs) do
    case verify_address(avs) do
      {:ok, _} -> true
      _ -> false
    end
  end

  # credo:disable-for-next-line Credo.Check.Refactor.CyclomaticComplexity
  def verify_address(avs) do
    case avs do
      "A" -> {:ok, "Match"}
      "B" -> {:ok, "Match"}
      "E" -> {:ok, "Address matches but name doesn't match."}
      "F" -> {:ok, "Address matches but name doesn't match."}
      "M" -> {:ok, "Match"}
      "O" -> {:ok, "Match"}
      "Y" -> {:ok, "Match"}
      "X" -> {:ok, "Match"}
      _ -> {:error, "Unable to verify address."}
    end
  end

  def zipcode_verified?(avs) do
    case verify_zipcode(avs) do
      {:ok, _} -> true
      _ -> false
    end
  end

  # credo:disable-for-next-line Credo.Check.Refactor.CyclomaticComplexity
  def verify_zipcode(avs) do
    case avs do
      "M" -> {:ok, "Match"}
      "P" -> {:ok, "Match"}
      "L" -> {:ok, "Match"}
      "Y" -> {:ok, "Match"}
      "X" -> {:ok, "Match"}
      "Z" -> {:ok, "Match"}
      "T" -> {:ok, "Match"}
      "D" -> {:ok, "Zipcode matches but name doesn't match."}
      "E" -> {:ok, "Zipcode matches but name doesn't match."}
      _ -> {:error, "Unable to verify zipcode."}
    end
  end

  def build_token_response({:ok, %{body: body}}) do
    xml = body |> parse
    success = xpath(xml, ~x"//response/receipt/ResSuccess/text()"s)
    if success == "true" do
      {:ok, parse_token_response(xml)}
    else
      {:error, parse_error_reponse(xml)}
    end
  end
  def build_token_response({:error, response}) do
    xml = response.body |> parse
    {:error, parse_error_reponse(xml)}
  end
  def build_token_response(_) do
    {:error, %Response{success: false, message: "Unable to tokenize credit card."}}
  end

  defp parse_token_response(xml) do
    xpath(xml, ~x"//response/receipt/DataKey/text()"s)
  end

  def build_generic_response({:ok, %{body: body}}) do
    xml = body |> parse
    #success = xpath(xml, ~x"//response/receipt/Success/text()"s)
    response_code = xpath(xml, ~x"//response/receipt/ResponseCode/text()"I) || 999
    success = response_code < 50
    if success do
      {:ok, parse_error_reponse(xml)} # ???
    else
      {:error, parse_error_reponse(xml)}
    end
  end
  def build_generic_response({:error, response}) do
    xml = response.body |> parse
    {:error, parse_error_reponse(xml)}
  end
  def build_generic_response(_) do
    {:error, %Response{success: false, message: "unable to complete request."}}
  end
end
