defmodule Matrex.Models.Account do

  import Comeonin.Bcrypt

  alias __MODULE__, as: This

  defstruct [
    :user,
    :password,
  ]

  def new(user, password) do
    %This{user: user, password: password}
  end


  def check_password(this, password) do
    case checkpw(this.password, password) do
      true -> :ok
      false -> {:error, :forbidden}
    end
  end


  def dummy_check_password, do: dummy_checkpw()

end
