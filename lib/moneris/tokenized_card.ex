defmodule Moneris.TokenizedCard do
  @moduledoc """
  Network tokenized credit card for use with an Apple Pay decrypted PKPaymentToken.

  https://developer.apple.com/library/ios/documentation/PassKit/Reference/PaymentTokenJSON/PaymentTokenJSON.html
  """

  defstruct [
    cryptogram: nil,    # raw payment cryptogram
    source: nil,        # apple_pay, android_pay
    card: nil,          # credit card information, including the device pan
  ]

  @type t :: %Moneris.TokenizedCard{
    cryptogram: String.t,
    source: String.t,
    card: Moneris.Card.t,
  }
end
