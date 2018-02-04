defmodule SalesTaxesTest do
  use ExUnit.Case
  import ExUnit.CaptureIO

  doctest SalesTaxes

  test "app can load and calculate sales taxes and total price correctly" do
    func = fn ->
      assert SalesTaxes.run == :ok
    end
    assert capture_io(func) == "1, book, 12.49\n1, music cd, 16.49\n1, imported bottle of perfume, 32.19\n\nSales Taxes: 5.70\nTotal: 61.17\n\n"
  end
end
