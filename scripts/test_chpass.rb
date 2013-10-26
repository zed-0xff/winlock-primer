require 'ffi'

module Netapi32
  extend FFI::Library

  ffi_lib "netapi32"
  ffi_convention :stdcall

  attach_function :net_user_change_password, 'NetUserChangePassword', [:buffer_in]*4, :int
end

old_password = '1111'
new_password = '2222'

Netapi32.net_user_change_password nil, nil,
  "#{old_password}\0".encode("UTF-16LE"),
  "#{new_password}\0".encode("UTF-16LE")
