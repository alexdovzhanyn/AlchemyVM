defmodule WaspVM do
  import Binary

  def bin_open(file_path) do
    {status, pid} =
      file_path
      |> File.open([:binary])

    {status, pid}
  end

  def bin_stream(pid) do
    [byte_array] =
      File.stream!("./addTwo_main.wasm", [:hex], 2048)
      |> Enum.map(fn elem -> Binary.to_hex(elem) end)


    String.codepoints(byte_array)
    |> Enum.chunk_every(2)
    |> Enum.map(fn chunks -> Enum.join(chunks) end)
    |> IO.inspect(limit: :infinity)
    #pid |> File.stream! |> Enum.to_list
  end


end



"""
<<0, 97, 115, 109, 1, 0, 0, 0, 1, 134, 128, 128, 128, 0, 1, 96, 1, 127, 1, 127,
  3, 130, 128, 128, 128, 0, 1, 0, 4, 132, 128, 128, 128, 0, 1, 112, 0, 0, 5,
  131, 128, 128, 128, 0, 1, 0, 1, 6, 129, 128, ...>>


  [
    "00", "61", "73", "6d", "01", "00", "00", "00",

    str_length, [Type, Type, Type, Type], Sec Size, No Types
    "01", "86", "80", "80", "80", "00", "01", "60",

    form, no params,
    "01", "7f", "01", "7f", "03", "82", "80", "80",
    "80", "00", "01", "00", "04", "84", "80", "80",
    "80", "00", "01", "70", "00", "00", "05", "83",
    "80", "80", "80", "00", "01", "00", "01", "06",
    "81", "80", "80", "80", "00", "00", "07", "91",
    "80", "80", "80", "00", "02", "06", "6d", "65",
    "6d", "6f", "72", "79", "02", "00", "04", "6d",
    "61", "69", "6e", "00", "00", "0a", "8d", "80",
    "80", "80", "00", "01", "87", "80", "80", "80",
    "00", "00", "20", "00", "41", "02", "6a", "0b"]


  1  (module
  2   (table 0 anyfunc)
  3   (memory $0 1)
  4   (export "memory" (memory $0))
  5   (export "main" (func $main))
  6   (func $main (; 0 ;) (param $0 i32) (result i32)
  7    (i32.add
  8     (get_local $0)
  9     (i32.const 2)
  10    )
  11   )
  12   )



  @magic <<0x00, 0x61, 0x73, 0x6D>>
 @version <<0x01, 0x00, 0x00, 0x00>>
"""
