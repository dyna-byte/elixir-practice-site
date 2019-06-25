defmodule Rumbl.CategoryRepoTest do
  use Rumbl.ModelCase
  alias Rumbl.Category

  test "alphabnetical orders by name" do
    ~w(c b a)
    |> Enum.each(fn name -> Repo.insert!(%Category{name: name}) end)

    query = Category.alphabetical(Category)
    query = from c in query, select: c.name

    assert Repo.all(query) == ~w(a b c)
  end

end
