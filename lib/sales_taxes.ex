defmodule SalesTaxes do
  @csv_path_env %{dev: 'input1.csv', test: 'input_test.csv'}
  @csv_path Path.join(['lib', @csv_path_env[Mix.env]])
  @nearest_number 0.05
  @scale_size 2
  @tax_pattern %{
                  free:         %{pattern: ~r/book|chocolate|pill/},
                  five_percent: %{pattern: ~r/imported/, value: 0.05},
                  common:       %{value: 0.1}
                }

  @moduledoc """
  Documentation for SalesTaxes.
  """

  @doc "Main function"
  def run do
    price_and_sales_tax_list = @csv_path |> import_from_csv

    sales_taxes = Enum.map(price_and_sales_tax_list, &(&1[:sales_tax]))
                  |> Enum.sum
                  |> number_format

    total       = Enum.map(price_and_sales_tax_list, &(&1[:price_tax_included]))
                  |> Enum.sum
                  |> number_format

    IO.puts """

    Sales Taxes: #{sales_taxes}
    Total: #{total}
    """
  end

  @doc "Import receipt details from the given CSV"
  def import_from_csv(path) do
    path
    |> File.stream!
    |> CSV.decode(headers: true)
    |> Stream.map(&(process_csv_row(&1)))
    |> Enum.map(&(%{sales_tax: &1[:sales_tax], price_tax_included: &1[:price_tax_included]}))
  end

  @doc "Process each row of CSV"
  def process_csv_row(row) do
    {:ok, row_data} = row
    row_data
    |> sales_tax_and_price_calc
  end

  @doc "Calculate total sales taxes and total price after including sales taxes"
  def sales_tax_and_price_calc(row_data) do
    total_rate = tax_rate(row_data["Product"])
    price      = String.to_float(row_data["Price"])
    sales_tax  = round_nearest(price*total_rate)

    price_with_tax_included = price + sales_tax

    IO.puts "#{row_data["Quantity"]}, #{row_data["Product"]}, #{number_format(price_with_tax_included)}"
    %{sales_tax: sales_tax, price_tax_included: price_with_tax_included}
  end

  @doc "Calcuale the total tax rates of each product"
  def tax_rate(product_name) do
    common_tax_rate   = @tax_pattern[:common][:value]

    required_tax_rate = case Regex.match?(@tax_pattern[:five_percent][:pattern], String.downcase(product_name)) do
                          true -> @tax_pattern[:five_percent][:value]
                          _ -> 0
                        end

    if Regex.match?(@tax_pattern[:free][:pattern], String.downcase(product_name)) do
      required_tax_rate + 0
    else
      common_tax_rate + required_tax_rate
    end
  end

  @doc "Rounding number nearest the specific given number, defaut: 0.05"
  def round_nearest(number, nearest_number \\ @nearest_number) do
    round(number / nearest_number) * nearest_number
    |> number_format
    |> String.to_float
  end

  @doc "Format to display 2 of digits to the right of the decimal point"
  def number_format(number) do
    :erlang.float_to_binary(number, [decimals: @scale_size])
  end
end
