defmodule Moneris do
  alias Moneris.{Gateway, Transaction}
  @moduledoc """
  Documentation for Moneris.
  """

  @doc """
  Purchase
  """
  def purchase(gateway, order, card) do
    xml = Transaction.build_card(card) ++ Transaction.build_order(order)

    gateway
    |> Gateway.post(:purchase, xml)
    |> Transaction.build_response
  end

  @doc """
  Purchase 3D-Secure with a raw cryptogram for Apple Pay, etc.
  """
  def purchase_3ds(gateway, order, network_tokenization_card) do
    xml = Transaction.build_card(network_tokenization_card.card) ++
      Transaction.build_network_tokenization(network_tokenization_card) ++
      Transaction.build_order(order)

    gateway
    |> Gateway.post(:purchase, xml)
    |> Transaction.build_response
  end

  def preauth(gateway, order, card) do
    xml = Transaction.build_card(card) ++ Transaction.build_order(order)

    gateway
    |> Gateway.post(:preauth, xml)
    |> Transaction.build_response
  end

  def capture(gateway, order) do
    xml = Transaction.build_capture(order)

    gateway
    |> Gateway.post(:completion, xml)
    |> Transaction.build_response
  end

  def release(gateway, order) do
    # releasing an order is a capture for 0 dollars
    xml = Transaction.build_capture(%{order | amount: 0})

    gateway
    |> Gateway.post(:completion, xml)
    |> Transaction.build_response
  end

  def void(gateway, order) do
    # you need to do a capture before you can do a void.
    xml = Transaction.build_refund(order)

    gateway
    |> Gateway.post(:purchasecorrection, xml)
    |> Transaction.build_response
  end

  def refund(gateway, order) do
    xml = Transaction.build_refund(order)

    gateway
    |> Gateway.post(:purchasecorrection, xml)
    |> Transaction.build_response
  end

  def partial_refund(gateway, order, refund_amount) do
    xml = Transaction.build_partial_refund(order, refund_amount)

    gateway
    |> Gateway.post(:refund, xml)
    |> Transaction.build_response
  end

  def verify(gateway, card) do
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
