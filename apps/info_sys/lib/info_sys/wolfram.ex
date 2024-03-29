defmodule InfoSys.Wolfram do

  require Logger
  import SweetXml
  alias InfoSys.Result

  def start_link(query, query_ref, owner, limit) do
    Task.start_link(__MODULE__, :fetch, [query, query_ref, owner, limit])
  end

  def fetch(query_str, query_ref, owner, _limit) do
    IO.puts("Fetching str" <> query_str)
    query_str
    |> fetch_xml()
    |> extract_answer()
    |> send_results(query_ref, owner)
  end

  defp send_results(nil, query_ref, owner) do
    IO.puts("Found nothing")
    send(owner, {:results, query_ref, []})
  end

  defp send_results(answer, query_ref, owner) do
    results = [%Result{backend: "wolfram", score: 95, text: to_string(answer)}]
    send(owner, {:results, query_ref, results})
  end

  @http Application.get_env(:info_sys, :wolfram)[:http_client] || :httpc
  defp fetch_xml(query_str) do
    {:ok, {_, _, body}} = @http.request(
      String.to_charlist("http://api.wolframalpha.com/v2/query" <>
      "?appid=#{app_id()}" <>
      "&input=#{URI.encode(query_str)}&format=plaintext"))
    body
  end

  defp extract_answer(body) do
    answer = body |> xpath(~x"/queryresult/pod[contains(@title, 'Result') or contains(@title, 'Definitions') or contains(@title, 'Response')]
      /subpod/plaintext/text()")

    if !answer do
      Logger.warn("Found nothing\n#{body}")
    end

    answer
  end

  defp app_id, do: Application.get_env(:info_sys, :wolfram)[:app_id]

end
