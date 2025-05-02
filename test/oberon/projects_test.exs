defmodule Oberon.ProjectsTest do
  use Oberon.DataCase

  alias Oberon.Projects

  describe "projects" do
    alias Oberon.Projects.Project

    import Oberon.AuthFixtures, only: [user_scope_fixture: 0]
    import Oberon.ProjectsFixtures

    @invalid_attrs %{title: nil, price: nil}

    test "get_project!/2 returns the project with given id" do
      scope = user_scope_fixture()
      project = project_fixture(scope)
      other_scope = user_scope_fixture()
      assert Projects.get_project!(scope, project.id) == project
    end

    test "create_project/2 with valid data creates a project" do
      valid_attrs = %{title: "some title", price: 120.5}
      scope = user_scope_fixture()

      assert {:ok, %Project{} = project} = Projects.create_project(scope, valid_attrs)
      assert project.title == "some title"
      assert project.price == Decimal.new("120.5")
      assert project.user_id == scope.user.id
    end

    test "create_project/2 with invalid data returns error changeset" do
      scope = user_scope_fixture()
      assert {:error, %Ecto.Changeset{}} = Projects.create_project(scope, @invalid_attrs)
    end

    test "update_project/3 with valid data updates the project" do
      scope = user_scope_fixture()
      project = project_fixture(scope)
      update_attrs = %{title: "some updated title", price: 456.7}

      assert {:ok, %Project{} = project} = Projects.update_project(scope, project, update_attrs)
      assert project.title == "some updated title"
      assert project.price == Decimal.new("456.7")
    end

    test "update_project/3 with invalid scope raises" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      project = project_fixture(scope)

      assert_raise MatchError, fn ->
        Projects.update_project(other_scope, project, %{})
      end
    end

    test "update_project/3 with invalid data returns error changeset" do
      scope = user_scope_fixture()
      project = project_fixture(scope)
      assert {:error, %Ecto.Changeset{}} = Projects.update_project(scope, project, @invalid_attrs)
      assert project == Projects.get_project!(scope, project.id)
    end

    test "delete_project/2 deletes the project" do
      scope = user_scope_fixture()
      project = project_fixture(scope)
      assert {:ok, %Project{}} = Projects.delete_project(scope, project)
      assert_raise Ecto.NoResultsError, fn -> Projects.get_project!(scope, project.id) end
    end

    test "delete_project/2 with invalid scope raises" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      project = project_fixture(scope)
      assert_raise MatchError, fn -> Projects.delete_project(other_scope, project) end
    end

    test "change_project/2 returns a project changeset" do
      scope = user_scope_fixture()
      project = project_fixture(scope)
      assert %Ecto.Changeset{} = Projects.change_project(scope, project)
    end
  end

  describe "attachments" do
    alias Oberon.Projects.Attachment

    import Oberon.ProjectsFixtures

    @invalid_attrs %{name: nil, type: nil, value: nil, placeholder: nil}

    test "list_attachments/0 returns all attachments" do
      attachment = attachment_fixture()
      assert Projects.list_attachments() == [attachment]
    end

    test "get_attachment!/1 returns the attachment with given id" do
      attachment = attachment_fixture()
      assert Projects.get_attachment!(attachment.id) == attachment
    end

    test "create_attachment/1 with valid data creates a attachment" do
      valid_attrs = %{
        name: "some name",
        type: "some type",
        value: "some value",
        placeholder: "some placeholder"
      }

      assert {:ok, %Attachment{} = attachment} = Projects.create_attachment(valid_attrs)
      assert attachment.name == "some name"
      assert attachment.type == "some type"
      assert attachment.value == "some value"
      assert attachment.placeholder == "some placeholder"
    end

    test "create_attachment/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Projects.create_attachment(@invalid_attrs)
    end

    test "update_attachment/2 with valid data updates the attachment" do
      attachment = attachment_fixture()

      update_attrs = %{
        name: "some updated name",
        type: "some updated type",
        value: "some updated value",
        placeholder: "some updated placeholder"
      }

      assert {:ok, %Attachment{} = attachment} =
               Projects.update_attachment(attachment, update_attrs)

      assert attachment.name == "some updated name"
      assert attachment.type == "some updated type"
      assert attachment.value == "some updated value"
      assert attachment.placeholder == "some updated placeholder"
    end

    test "update_attachment/2 with invalid data returns error changeset" do
      attachment = attachment_fixture()
      assert {:error, %Ecto.Changeset{}} = Projects.update_attachment(attachment, @invalid_attrs)
      assert attachment == Projects.get_attachment!(attachment.id)
    end

    test "delete_attachment/1 deletes the attachment" do
      attachment = attachment_fixture()
      assert {:ok, %Attachment{}} = Projects.delete_attachment(attachment)
      assert_raise Ecto.NoResultsError, fn -> Projects.get_attachment!(attachment.id) end
    end

    test "change_attachment/1 returns a attachment changeset" do
      attachment = attachment_fixture()
      assert %Ecto.Changeset{} = Projects.change_attachment(attachment)
    end
  end

  describe "vote" do
    alias Oberon.Projects.Vote

    import Oberon.AuthFixtures, only: [user_scope_fixture: 0]
    import Oberon.ProjectsFixtures

    @invalid_attrs %{vote_type: nil}

    test "list_vote/1 returns all scoped vote" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      vote = vote_fixture(scope)
      other_vote = vote_fixture(other_scope)
      assert Projects.list_vote(scope) == [vote]
      assert Projects.list_vote(other_scope) == [other_vote]
    end

    test "get_vote!/2 returns the vote with given id" do
      scope = user_scope_fixture()
      vote = vote_fixture(scope)
      other_scope = user_scope_fixture()
      assert Projects.get_vote!(scope, vote.id) == vote
      assert_raise Ecto.NoResultsError, fn -> Projects.get_vote!(other_scope, vote.id) end
    end

    test "create_vote/2 with valid data creates a vote" do
      valid_attrs = %{vote_type: :approve}
      scope = user_scope_fixture()

      assert {:ok, %Vote{} = vote} = Projects.create_vote(scope, valid_attrs)
      assert vote.vote_type == :approve
      assert vote.user_id == scope.user.id
    end

    test "create_vote/2 with invalid data returns error changeset" do
      scope = user_scope_fixture()
      assert {:error, %Ecto.Changeset{}} = Projects.create_vote(scope, @invalid_attrs)
    end

    test "update_vote/3 with valid data updates the vote" do
      scope = user_scope_fixture()
      vote = vote_fixture(scope)
      update_attrs = %{vote_type: :disapprove}

      assert {:ok, %Vote{} = vote} = Projects.update_vote(scope, vote, update_attrs)
      assert vote.vote_type == :disapprove
    end

    test "update_vote/3 with invalid scope raises" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      vote = vote_fixture(scope)

      assert_raise MatchError, fn ->
        Projects.update_vote(other_scope, vote, %{})
      end
    end

    test "update_vote/3 with invalid data returns error changeset" do
      scope = user_scope_fixture()
      vote = vote_fixture(scope)
      assert {:error, %Ecto.Changeset{}} = Projects.update_vote(scope, vote, @invalid_attrs)
      assert vote == Projects.get_vote!(scope, vote.id)
    end

    test "delete_vote/2 deletes the vote" do
      scope = user_scope_fixture()
      vote = vote_fixture(scope)
      assert {:ok, %Vote{}} = Projects.delete_vote(scope, vote)
      assert_raise Ecto.NoResultsError, fn -> Projects.get_vote!(scope, vote.id) end
    end

    test "delete_vote/2 with invalid scope raises" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      vote = vote_fixture(scope)
      assert_raise MatchError, fn -> Projects.delete_vote(other_scope, vote) end
    end

    test "change_vote/2 returns a vote changeset" do
      scope = user_scope_fixture()
      vote = vote_fixture(scope)
      assert %Ecto.Changeset{} = Projects.change_vote(scope, vote)
    end
  end
end
