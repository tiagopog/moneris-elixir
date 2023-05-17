defmodule Moneris.Gateway do
  import XmlBuilder

  @moduledoc """
  Gateway for development or production.
  """

  defstruct [:url, :store_id, :api_token]
  @type t :: %Moneris.Gateway{url: String.t, store_id: String.t, api_token: String.t}

  @spec new(atom, String.t, String.t) :: Moneris.Gateway.t
  def new(atom, store_id \\ "store1", api_token \\ "yesguy")

  @spec new(atom, String.t, String.t) :: Moneris.Gateway.t
  def new(:production, store_id, api_token) do
    %Moneris.Gateway{
      url: "https://www3.moneris.com/gateway2/servlet/MpgRequest'",
      store_id: store_id,
      api_token: api_token,
    }
  end

  @spec new(atom, String.t, String.t) :: Moneris.Gateway.t
  def new(:development, store_id, api_token) do
    %Moneris.Gateway{
      url: "https://esqa.moneris.com/gateway2/servlet/MpgRequest",
      store_id: store_id,
      api_token: api_token,
    }
  end

  @spec new(String.t, String.t, String.t) :: Moneris.Gateway.t
  def new(endpoint, store_id, api_token) do
    %Moneris.Gateway{
      url: endpoint,
      store_id: store_id,
      api_token: api_token,
    }
  end

  @spec post(Moneris.Gateway.t, atom, String.t) :: {}
  def post(gateway, action, xml) do
    body = [
      element(:store_id, gateway.store_id),
      element(:api_token, gateway.api_token),
      element(action, xml)
    ]
    document = generate(XmlBuilder.doc(:request, body))
    HTTPoison.post(gateway.url, document, headers(), [timeout: 10_000, recv_timeout: 10_000])
  end

  defp headers do
    [
      "Content-type": "application/xml",
      "User-Agent": "Elixir - 1.5.3 - Soundpays"
    ]
  end
end
