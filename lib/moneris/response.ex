defmodule Moneris.Response do
  @moduledoc """
  Response.
  """

  defstruct [
    order_id: nil,           # unique order id string
    amount:     0,           # amount of purchase in cents
    transaction_number: nil, # assigned by Moneris once the order is complete
    reference_number:   nil, # assigned by Moneris once the order is complete
    message: nil,            # assigned by Moneris once the order is complete
    code: 0,                 # assigned by Moneris once the order is complete
    cvd: nil,                # assigned by Moneris once the order is complete
    avs: nil,                # assigned by Moneris once the order is complete
    cvd_verified: nil,       # assigned by Moneris once the order is complete
    address_verified: nil,   # assigned by Moneris once the order is complete
    zipcode_verified: nil,   # assigned by Moneris once the order is complete
    success: nil             # assigned by Moneris once the order is complete
  ]

  @type t :: %Moneris.Response{
    order_id:           String.t,
    amount:             integer,
    transaction_number: String.t,
    reference_number:   String.t,
    message:            String.t,
    code:               integer,
    cvd:                String.t,
    avs:                String.t,
    cvd_verified:       boolean,
    address_verified:   boolean,
    zipcode_verified:   boolean,
    success:            boolean
  }

  def new(options \\ %{})
  def new(%{} = options) do
    Map.merge(%Moneris.Response{order_id: UUID.uuid4(:hex)}, options)
  end
end
