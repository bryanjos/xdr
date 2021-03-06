defmodule XDR.Type.VariableArrayTest do
  use ExUnit.Case
  alias XDR.Type.VariableArray
  alias XDR.Type.Int

  defmodule XDR.Type.VariableArrayTest.Max0 do
    use VariableArray, spec: [max_len: 0, type: Int]
  end

  defmodule XDR.Type.VariableArrayTest.Max1 do
    use VariableArray, spec: [max_len: 1, type: Int]
  end

  defmodule XDR.Type.VariableArrayTest.Max2 do
    use VariableArray, spec: [max_len: 2, type: Int]
  end

  defmodule XDR.Type.VariableArrayTest.InvalidLength do
    import CompileTimeAssertions

    assert_compile_time_raise RuntimeError, "invalid length", fn ->
      use XDR.Type.VariableArray, spec: [max_len: -1, type: Int]
    end
  end

  alias XDR.Type.VariableArrayTest.{Max0, Max1, Max2}

  test "length" do
    assert Max0.length === :variable
    assert Max1.length === :variable
    assert Max2.length === :variable
  end

  test "new" do
    assert Max0.new == {:ok, []}
    assert Max0.new([]) == {:ok, []}
    assert Max1.new([]) == {:ok, []}
    assert Max1.new([0]) == {:ok, [0]}
    assert Max1.new([1]) == {:ok, [1]}

    assert Max0.new([1]) == {:error, :invalid}
    assert Max1.new([0, 1]) == {:error, :invalid}
    assert Max0.new({1}) == {:error, :invalid}
    assert Max1.new({0, 1}) == {:error, :invalid}
    assert Max0.new(false) == {:error, :invalid}
    assert Max0.new(nil) == {:error, :invalid}
    assert Max0.new(0) == {:error, :invalid}
  end

  test "valid?" do
    assert Max2.valid?([0]) == true
    assert Max2.valid?([0, 1]) == true

    assert Max1.valid?([0, 0]) == false
    assert Max2.valid?([0, 0, 0]) == false
    assert Max1.valid?(false) == false
    assert Max1.valid?(nil) == false
    assert Max1.valid?(0) == false
  end

  test "encode" do
    assert Max0.encode([]) == {:ok, <<0, 0, 0, 0>>}
    assert Max1.encode([0]) == {:ok, <<0, 0, 0, 1, 0, 0, 0, 0>>}
    assert Max2.encode([1, 2]) == {:ok, <<0, 0, 0, 2, 0, 0, 0, 1, 0, 0, 0, 2>>}
    assert Max2.encode([3, 4]) == {:ok, <<0, 0, 0, 2, 0, 0, 0, 3, 0, 0, 0, 4>>}
  end

  test "decode" do
    assert Max0.decode(<<0, 0, 0, 0>>) == {:ok, {[], <<>>}}
    assert Max0.decode(<<0, 0, 0, 0, 0, 0, 0, 1>>) == {:ok, {[], <<0, 0, 0, 1>>}}
    assert Max1.decode(<<0, 0, 0, 1, 0, 0, 0, 0>>) == {:ok, {[0], <<>>}}
    assert Max2.decode(<<0, 0, 0, 1, 0, 0, 0, 1>>) == {:ok, {[1], <<>>}}
    assert Max2.decode(<<0, 0, 0, 2, 0, 0, 0, 1, 0, 0, 0, 2>>) == {:ok, {[1, 2], <<>>}}
    assert Max2.decode(<<0, 0, 0, 2, 0, 0, 0, 3, 0, 0, 0, 4>>) == {:ok, {[3, 4], <<>>}}

    assert Max2.decode(<<0, 0, 0, 1, 65, 1, 0>>) == {:error, :invalid}
    assert Max2.decode(<<0, 0, 0, 3, 0, 0, 0, 0>>) == {:error, :xdr_length_exceeds_defined_max}
    assert Max2.decode(<<0, 0, 0, 2, 0, 0, 0, 1>>) == {:error, :invalid_xdr_length}
  end
end
