defmodule MagWeb.HomeLive do
  use MagWeb, :live_view

  alias Mag.Posts
  alias Phoenix.LiveView.JS

  def mount(_params, _session, socket) do
    all_posts = Posts.list_posts()
    featured_posts = Enum.slice(all_posts, length(all_posts) - 12, 12) |> Enum.reverse()
    all_posts = Enum.slice(all_posts, 0, length(all_posts) - 12) |> Enum.reverse()

    {:ok,
     assign(socket,
       all_posts: all_posts,
       posts: Enum.slice(all_posts, 0..4),
       featured_posts: featured_posts,
       current_count: 5,
       show: false,
       form: to_form(email_changeset(%{}), as: "subscribe"),
       index: 0,
       post: nil
     )}
  end

  def handle_event("validate", %{"subscribe" => params}, socket) do
    {:noreply, assign(socket, form: to_form(email_changeset(params), as: "subscribe"))}
  end

  def handle_event("save", %{"subscribe" => params}, socket) do
    socket =
      case email_changeset(params).valid? do
        true ->
          Mag.Posts.subscribe(params["email"])
          assign(socket, form: to_form(%{email_changeset(%{}) | action: nil}, as: "subscribe"))

        false ->
          socket
      end

    {:noreply, socket}
  end

  def handle_event("show_post", %{"index" => index}, socket) do
    {:noreply,
     assign(socket,
       show: true,
       post: Enum.at(socket.assigns.posts, String.to_integer(index), hd(socket.assigns.posts))
     )}
  end

  def handle_event("show_featured_post", %{"index" => index}, socket) do
    {:noreply,
     assign(socket,
       show: true,
       post:
         Enum.at(
           socket.assigns.featured_posts,
           String.to_integer(index),
           hd(socket.assigns.featured_posts)
         )
     )}
  end

  def handle_event("hide_post", _payload, socket) do
    {:noreply, assign(socket, show: false)}
  end

  def handle_event("load-more", _paylaod, socket) do
    {:reply, %{},
     assign(socket,
       current_count: socket.assigns.current_count + 5,
       posts: Enum.slice(socket.assigns.all_posts, 0..(socket.assigns.current_count + 5))
     )}
  end

  def email_form(assigns) do
    ~H"""
    <div>
      <.form
        class="flex gap-4 flex-col my-4 w-full"
        for={@form}
        phx-change="validate"
        phx-submit="save"
      >
        <.input
          autofocus={false}
          type="text"
          class=""
          placeholder="notdepressed@gmail.com"
          phx-debounce="300"
          field={@form[:email]}
        />
        <.button phx-disable-with="Subscribing...">Subscribe</.button>
      </.form>
    </div>
    """
  end

  def email_changeset(params) do
    data = %{}
    types = %{email: :string}

    changeset =
      {data, types}
      |> Ecto.Changeset.cast(params, Map.keys(types))
      |> Ecto.Changeset.validate_required([:email])
      |> validate_email

    %{changeset | action: :validated}
  end

  @mail_regex ~r/^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,4}$/

  def validate_email(changeset) do
    changeset
    |> Ecto.Changeset.validate_format(:email, @mail_regex)
  end
end
