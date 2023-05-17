# MonerisElixir

Unofficial Elixir client for processing payments through [Moneris](https://www.moneris.com/).

## Installation

```elixir
def deps do
  [
    {:moreris, git: "https://github.com/tiagopog/moneris-elixir.git"}
  ]
end
```

## Usage

### Example of Pre-Authorization + Completion with CVD

```elixir
# Set up the gateway infomation:
iex> gateway = Moneris.Gateway.new(:development, "{{username}}", "{{api_key}}")
%Moneris.Gateway{
  url: "https://esqa.moneris.com/gateway2/servlet/MpgRequest",
  store_id: "{{username}}",
  api_token: "{{api_key}}"
}

# Pre-authorize the payment:
iex> Moneris.preauth(gateway, order, card)
{:ok,
 %Moneris.Response{
   order_id: "e7e4a53245084998b5f7fa8155ffde10",
   amount: 1001,
   transaction_number: "10-0_482",
   reference_number: "660188080010010130",
   message: "Approved",
   code: 0,
   cvd: "1M",
   avs: "",
   cvd_verified: false,
   address_verified: false,
   zipcode_verified: false,
   success: true
 }}

# Update the order with some data from pre-authorization step:
iex> order = %Moneris.Order{order | transaction_number: "10-0_482", reference_number: "660188080010010130"}
%Moneris.Order{
  order_id: "e7e4a53245084998b5f7fa8155ffde10",
  amount: 1001,
  crypt_type: 7,
  cust_id: "ecom-order-num-5",
  transaction_number: "10-0_482",
  reference_number: "660188080010010130"
}

# Capture the payment:
iex> Moneris.capture(gateway, order)
{:ok,
 %Moneris.Response{
   order_id: "e7e4a53245084998b5f7fa8155ffde10",
   amount: 1001,
   transaction_number: "11-1_482",
   reference_number: "660188080010010140",
   message: "Approved",
   code: 0,
   cvd: "",
   avs: "",
   cvd_verified: false,
   address_verified: false,
   zipcode_verified: false,
   success: true
 }}
```
