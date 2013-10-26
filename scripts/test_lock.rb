#coding: utf-8

require "ffi"

module User32
  extend FFI::Library

  ffi_lib "user32"
  ffi_convention :stdcall

  # use MessageBoxA if you want to pass it strings with ASCII encoding
  attach_function :message_box, 'MessageBoxW', 
                  [ :pointer, :buffer_in, :buffer_in, :int ], :int

  attach_function :get_last_input_info, 'GetLastInputInfo', [:pointer], :int
  attach_function :lock_workstation, 'LockWorkStation', [], :int
end

User32.lock_workstation
