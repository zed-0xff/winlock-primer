require 'ffi'

MB_SYSTEMMODAL = 0x1000
MB_ICONSTOP    = 0x10

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

module Kernel32
  extend FFI::Library

  ffi_lib "kernel32"
  ffi_convention :stdcall

  attach_function :get_tick_count, 'GetTickCount', [], :int
end

module Netapi32
  extend FFI::Library

  ffi_lib "netapi32"
  ffi_convention :stdcall

  attach_function :net_user_change_password, 'NetUserChangePassword', [:buffer_in]*4, :int
  #attach_function :net_user_enum, 'NetUserEnum', [:buffer_in, :int, :int, ... ], :int
end

