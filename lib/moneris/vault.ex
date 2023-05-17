defmodule Moneris.Vault do
  @moduledoc """
  Module for tokenizing credit cards with Moneris Vault.
  """

  alias Moneris.{Card, Gateway, Order, Transaction}

  def add(%Gateway{} = gateway, %Card{} = card, verification_id) do
    case tokenize(card, gateway) do
      {:ok, token} -> verify(token, card, gateway, verification_id)
      {:error, message} -> {:error, message}
      _ -> {:error, "unable to tokenize card."}
    end
  end

  def remove(%Gateway{} = gateway, token) do
    xml = Transaction.build_token(token)

    gateway
    |> Gateway.post(:res_delete, xml)
    |> Transaction.build_response
  end

  def update(%Gateway{} = gateway, token, card) do
    xml = Transaction.build_token(token) ++ Transaction.build_card(card)

    gateway
    |> Gateway.post(:res_update_cc, xml)
    |> Transaction.build_response
  end

  def purchase(%Gateway{} = gateway, token, %Order{} = order) do
    xml = Transaction.build_token(token) ++ Transaction.build_order(order)

    gateway
    |> Gateway.post(:res_purchase_cc, xml)
    |> Transaction.build_response
  end

  def partial_refund(%Gateway{} = gateway, token, %Order{} = order, refund_amount) do
    xml = Transaction.build_token(token) ++ Transaction.build_partial_refund_for_vault(order, refund_amount)

    gateway
    |> Gateway.post(:res_ind_refund_cc, xml)
    |> Transaction.build_response
  end

  defp tokenize(%Card{} = card, %Gateway{} = gateway) do
    xml = Transaction.build_card(card) ++ Transaction.build_avs(card) ++ Transaction.default_crypt_type()

    gateway
    |> Gateway.post(:res_add_cc, xml)
    |> Transaction.build_token_response
  end

  defp verify(token, %Card{} = card, %Gateway{} = gateway, verification_id) do
    xml = Transaction.build_token(token) ++
          Transaction.build_verification(card.expdate, verification_id) ++
          Transaction.build_cvd(card) ++
          Transaction.build_avs(card) ++
          Transaction.default_crypt_type()

    response = gateway
    |> Gateway.post(:res_card_verification_cc, xml)
    |> Transaction.build_generic_response

    case response do
      {:ok, _} -> {:ok, token}
      {:error, message} -> {:error, message}
      _ -> {:error, "unable to tokenize card."}
    end
  end
end
