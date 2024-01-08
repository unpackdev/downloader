// SPDX-License-Identifier: Unlicense
pragma solidity >=0.7.6;

/// @notice Based on EIP-3448
// Audit-1: ok
contract MetaProxyFactory {
  /// @dev Creates a child with metadata from calldata.
  /// Copies everything from calldata except the first 4 bytes.
  function _metaProxyFromCalldata () internal returns (address addr) {
    // the following assembly code (init code + contract code) constructs a metaproxy.
    assembly {
      // load free memory pointer as per solidity convention
      let start := mload(64)
      // copy
      let ptr := start
      // deploy code (11 bytes) + first part of the proxy (21 bytes)
      mstore(ptr, 0x600b380380600b3d393df3363d3d373d3d3d3d60368038038091363936013d73)
      ptr := add(ptr, 32)

      // store the address of the contract to be called
      mstore(ptr, shl(96, address()))
      // 20 bytes
      ptr := add(ptr, 20)

      // the remaining proxy code...
      mstore(ptr, 0x5af43d3d93803e603457fd5bf300000000000000000000000000000000000000)
      // ...13 bytes
      ptr := add(ptr, 13)

      // now calculdate the size and copy the metadata
      // - 4 bytes function signature
      let size := sub(calldatasize(), 4)
      // copy
      calldatacopy(ptr, 4, size)
      ptr := add(ptr, size)
      // store the size of the metadata at the end of the bytecode
      mstore(ptr, size)
      ptr := add(ptr, 32)

      // The size is deploy code + contract code + calldatasize - 4 + 32.
      addr := create(0, start, sub(ptr, start))
    }
  }
}
