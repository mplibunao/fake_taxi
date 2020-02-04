defmodule FakeTaxiTest do
  use ExUnit.Case
  doctest FakeTaxi

  test "greets the world" do
    assert FakeTaxi.hello() == :world
  end
end
