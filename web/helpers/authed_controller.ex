defmodule Matrex.AuthedController do
  defmacro __using__(_) do
    quote do
      def action(conn, _), do: Matrex.AuthedController.__action__(__MODULE__, conn)
      defoverridable action: 2
    end
  end

  def __action__(controller, conn) do
    args = [conn, conn.params, conn.assigns[:access_token]]
    apply(controller, Phoenix.Controller.action_name(conn), args)
  end
end
