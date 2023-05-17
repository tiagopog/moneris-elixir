defmodule Moneris.Order do
  @moduledoc """
  Order.
  """

  defstruct [
    order_id: UUID.uuid4(:hex),           # unique order id string
    amount:     0,           # amount of purchase in cents
    crypt_type: 7,           # leave this as 7-SSL enabled merchant unless its a 5-Authenticated E-commerce Transaction (VBV)
    cust_id: nil,            # optional, (up to 50 alpha). used for searching in portal. invoice number?
    transaction_number: nil, # assigned by Moneris once the order is complete
    reference_number:   nil  # assigned by Moneris once the order is complete
  ]

  @type t :: %Moneris.Order{
    order_id:           String.t,
    amount:             integer,
    crypt_type:         integer,
    cust_id:            String.t,
    transaction_number: String.t,
    reference_number:   String.t
  }

  def new(options \\ %{})
  def new(%{} = options) do
    Map.merge(%Moneris.Order{order_id: UUID.uuid4(:hex)}, options)
  end
end
