defmodule InfoSys.Backends.WolframTest do
  use ExUnit.Case, async: true
  alias InfoSys.Wolfram

  test "makes request, reports results then terminates" do
    ref = make_ref()
    {:ok, pid} = Wolfram.start_link("1+1", ref, self(), 1)
    mon = Process.monitor(pid)

    assert_receive {:results, ^ref, [%InfoSys.Result{text: "2"}]}
    assert_receive {:DOWN, ^mon, :process, ^pid, :normal}
  end

end
