defmodule Moneris.Vault do
  alias Moneris.{Gateway, Transaction}

  @moduledoc """
  Vault.
  """

  def add(gateway, card, verification_id) do
    case tokenize(card, gateway) do
      {:ok, token} -> verify(token, card, gateway, verification_id)
      {:error, message} -> {:error, message}
      _ -> {:error, "unable to tokenize card."}
    end
  end

  def remove(gateway, token) do
    xml = Transaction.build_token(token)

    gateway
    |> Gateway.post(:res_delete, xml)
    |> Transaction.build_response
  end

  def update(gateway, token, card) do
    xml = Transaction.build_token(token) ++ Transaction.build_card(card)

    gateway
    |> Gateway.post(:res_update_cc, xml)
    |> Transaction.build_response
  end

  def purchase(gateway, token, order) do
    xml = Transaction.build_token(token) ++ Transaction.build_order(order)

    gateway
    |> Gateway.post(:res_purchase_cc, xml)
    |> Transaction.build_response
  end

  def partial_refund(gateway, token, order, refund_amount) do
    xml = Transaction.build_token(token) ++ Transaction.build_partial_refund_for_vault(order, refund_amount)

    gateway
    |> Gateway.post(:res_ind_refund_cc, xml)
    |> Transaction.build_response
  end

  defp tokenize(card, gateway) do
    xml = Transaction.build_card(card) ++ Transaction.build_avs(card) ++ Transaction.default_crypt_type()

    gateway
    |> Gateway.post(:res_add_cc, xml)
    |> Transaction.build_token_response
  end

  defp verify(token, card, gateway, verification_id) do
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
