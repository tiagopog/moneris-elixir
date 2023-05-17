defmodule Moneris do
  @moduledoc """
  Documentation for Moneris.
  """

  alias Moneris.{Card, Gateway, Order, TokenizedCard, Transaction}

  @doc """
  Purchase operation.
  """
  def purchase(%Gateway{} = gateway, %Order{} = order, %Card{} = card) do
    xml = Transaction.build_card(card) ++ Transaction.build_order(order)

    gateway
    |> Gateway.post(:purchase, xml)
    |> Transaction.build_response
  end

  @doc """
  Purchase 3D-Secure with a raw cryptogram for Apple Pay, etc.
  """
  def purchase_3ds(%Gateway{} = gateway, %Order{} = order, %TokenizedCard{} = network_tokenization_card) do
    xml = Transaction.build_card(network_tokenization_card.card) ++
      Transaction.build_network_tokenization(network_tokenization_card) ++
      Transaction.build_order(order)

    gateway
    |> Gateway.post(:purchase, xml)
    |> Transaction.build_response
  end

  @doc """
  Pre-authorizing payment operation.
  """
  def preauth(%Gateway{} = gateway, %Order{} = order, %Card{} = card) do
    xml = Transaction.build_card(card) ++ Transaction.build_order(order)

    gateway
    |> Gateway.post(:preauth, xml)
    |> Transaction.build_response
  end

  @doc """
  Capture payment operation.
  """
  def capture(%Gateway{} = gateway, %Order{} = order) do
    xml = Transaction.build_capture(order)

    gateway
    |> Gateway.post(:completion, xml)
    |> Transaction.build_response
  end

  def release(%Gateway{} = gateway, %Order{} = order) do
    # releasing an order is a capture for 0 dollars
    xml = Transaction.build_capture(%{order | amount: 0})

    gateway
    |> Gateway.post(:completion, xml)
    |> Transaction.build_response
  end

  def void(%Gateway{} = gateway, %Order{} = order) do
    # you need to do a capture before you can do a void.
    xml = Transaction.build_refund(order)

    gateway
    |> Gateway.post(:purchasecorrection, xml)
    |> Transaction.build_response
  end

  def refund(%Gateway{} = gateway, %Order{} = order) do
    xml = Transaction.build_refund(order)

    gateway
    |> Gateway.post(:purchasecorrection, xml)
    |> Transaction.build_response
  end

  def partial_refund(%Gateway{} = gateway, %Order{} = order, refund_amount) do
    xml = Transaction.build_partial_refund(order, refund_amount)

    gateway
    |> Gateway.post(:refund, xml)
    |> Transaction.build_response
  end

  def verify(%Gateway{} = gateway, %Card{} = card) do
    uuid = UUID.uuid4(:hex)
    xml = Transaction.build_card(card) ++
          Transaction.build_verification(card.expdate, uuid) ++
          Transaction.build_cvd(card) ++
          Transaction.build_avs(card) ++
          Transaction.default_crypt_type()

    response = gateway
    |> Gateway.post(:card_verification, xml)
    |> Transaction.build_generic_response

    case response do
      {:ok, message} -> {:ok, message}
      {:error, message} -> {:error, message}
      _ -> {:error, "unable to verify card."}
    end
  end
end
