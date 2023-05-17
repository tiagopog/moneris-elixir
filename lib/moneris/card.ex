defmodule Moneris.Card do
  @moduledoc """
  Credit card information.
  """

  defstruct [
    name: nil,          # card holder name
    email: nil,         # card holder name
    phone: nil,         # card holder name
    pan: nil,           # card number
    expdate: nil,       # expiry date YYMM
    cvv: nil,           # optional, verified if present (3-4 digits)
    zip: nil,           # optional, verified if present (up to 10 alpha)
    country: nil,       # optional (3 alpha)
    note: nil           # optional (3 alpha)
  ]

  @type t :: %Moneris.Card{
    name: String.t,
    email: String.t,
    phone: String.t,
    pan: String.t,
    expdate: String.t,
    cvv: String.t,
    zip: String.t,
    country: String.t,
    note: String.t
  }
end
