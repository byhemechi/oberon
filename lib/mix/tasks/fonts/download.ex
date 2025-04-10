defmodule Mix.Tasks.Fonts.Download do
  require Logger
  use Mix.Task

  @assets_dir Path.expand("priv/static/assets")

  defp get_npm_data(package_name) when is_binary(package_name) do
    %{status: 200, body: data} =
      URI.parse("https://registry.npmjs.org/")
      |> URI.append_path("/" <> package_name)
      |> Req.get!()

    data
  end

  defp download_npm_package(npm_data, :latest) do
    %{"dist-tags" => %{"latest" => latest_version}} = npm_data
    download_npm_package(npm_data, latest_version)
  end

  defp download_npm_package(npm_data, version) do
    %{
      "name" => "@fontsource/" <> font_name,
      "versions" => %{
        ^version => %{"dist" => %{"tarball" => tarball_url, "shasum" => expected_sha_sum}}
      }
    } =
      npm_data

    %{status: 200, body: tarball} = Req.get!(tarball_url, raw: true)

    expected_sha_sum = Base.decode16!(expected_sha_sum, case: :lower)
    sha_sum = :crypto.hash(:sha, tarball)

    if expected_sha_sum != sha_sum do
      IO.inspect({expected_sha_sum, sha_sum})
      raise "Checksum did not match"
    else
      Logger.info("Checksum matched")
    end

    (out_dir = Path.join([@assets_dir, "/fonts"]))
    |> File.mkdir_p!()

    :erl_tar.extract({:binary, tarball}, [
      :compressed,
      cwd: String.to_charlist(out_dir)
    ])

    font_dir = Path.join([out_dir, font_name])

    File.rm_rf!(font_dir)
    File.rename!(Path.join([out_dir, "package"]), font_dir)

    font_dir
  end

  def generate_bundle_css(font_dir) do
    minified =
      File.ls!(font_dir)
      |> Enum.filter(fn i ->
        case Integer.parse(i) do
          {_size, ".css"} -> true
          {_size, "-italic.css"} -> true
          _ -> false
        end
      end)
      |> Enum.reduce(
        "",
        fn el, acc ->
          acc <> File.read!(Path.join([font_dir, el]))
        end
      )
      |> String.replace(~r(/\*.*?\*/), "")
      |> String.replace(~r/\n */, "")

    File.write!(Path.join(font_dir, "all.min.css"), minified)
  end

  def run([]) do
    Logger.error("A font name is required")
  end

  def run([font_name | _]) do
    {:ok, _} = Application.ensure_all_started(:req)

    Logger.info("Downloading IBM Plex Sans")

    get_npm_data("@fontsource/" <> font_name)
    |> download_npm_package(:latest)
    |> generate_bundle_css()
  end
end
