defmodule Oberon.Auth.Scope do
  @moduledoc """
  Defines the scope of the caller to be used throughout the app.

  The `Oberon.Auth.UserScope` allows public interfaces to receive
  information about the caller, such as if the call is initiated from an
  end-user, and if so, which user. Additionally, such a scope can carry fields
  such as "super user" or other privileges for use as authorization, or to
  ensure specific code paths can only be access for a given scope.

  It is useful for logging as well as for scoping pubsub subscriptions and
  broadcasts when a caller subscribes to an interface or performs a particular
  action.

  Feel free to extend the fields on this struct to fit the needs of
  growing application requirements.
  """

  alias Oberon.Auth.User

  defstruct user: nil,
            can_create_proposals: false,
            can_edit_proposals: false,
            can_remove_proposals: false,
            can_vote: false,
            can_create_payments: false,
            can_remove_comments: false

  @doc """
  Creates a scope for the given user.

  Returns nil if no user is given.
  """
  def for_user(user)

  def for_user(%User{role: :admin} = user) do
    %__MODULE__{
      user: user,
      can_create_proposals: true,
      can_edit_proposals: true,
      can_vote: true,
      can_create_payments: true,
      can_remove_comments: true,
      can_remove_proposals: true
    }
  end

  def for_user(%User{role: :horan} = user) do
    %__MODULE__{
      user: user,
      can_create_proposals: true,
      can_vote: true,
      can_create_payments: true
    }
  end

  def for_user(%User{role: :guest} = user) do
    %__MODULE__{
      user: user,
      can_create_proposals: true,
      can_vote: false,
      can_create_payments: true
    }
  end

  def for_user(%User{} = user) do
    %__MODULE__{user: user}
  end

  def for_user(nil), do: nil
end
