defmodule BigMarshTest do
  use ExUnit.Case
  doctest BigMarsh

  test "greets the world" do
    assert BigMarsh.hello() == :world
  end
end
