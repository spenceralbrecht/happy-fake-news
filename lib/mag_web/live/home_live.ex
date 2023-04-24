defmodule MagWeb.HomeLive do
  use MagWeb, :live_view

  alias Mag.Posts
  alias Phoenix.LiveView.JS

  def mount(_params, _session, socket) do
    {:ok, assign(socket, posts: Posts.list_posts(), show: nil, index: 0)}
  end

  def handle_event("show_post", %{"index" => index}, socket) do
    {:noreply, assign(socket, show: true, index: String.to_integer(index))}
  end

  def handle_event("hide_post", payload, socket) do
    {:noreply, assign(socket, show: false)}
  end
end
