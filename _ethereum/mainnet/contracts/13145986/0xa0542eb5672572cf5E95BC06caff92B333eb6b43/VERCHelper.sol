// SPDX-License-Identifier: Unlicense
pragma solidity >=0.7.6;

contract VERCHelper {
  /// @dev Returns the deployment bytecode (EIP-3448).
  /// Warning: writes to memory but does not advance the solidity memory pointer
  function _getInitCodeForVERC (address target, uint256 calldataStart, uint256 size) internal returns (bytes memory retVal) {
    // the following assembly code (init code + contract code) constructs a metaproxy.
    assembly {
      // load free memory pointer as per solidity convention
      retVal := mload(64)

      // skip 32 bytes
      let start := add(retVal, 32)
      // copy
      let ptr := start

      // deploy code (11 bytes) + first part of the proxy (21 bytes)
      mstore(ptr, 0x600b380380600b3d393df3363d3d373d3d3d3d60368038038091363936013d73)
      ptr := add(ptr, 32)

      // store the address of the contract to be called
      mstore(ptr, shl(96, target))
      // 20 bytes
      ptr := add(ptr, 20)

      // the remaining proxy code...
      mstore(ptr, 0x5af43d3d93803e603457fd5bf300000000000000000000000000000000000000)
      // ...13 bytes
      ptr := add(ptr, 13)

      // copy the metadata
      calldatacopy(ptr, calldataStart, size)
      ptr := add(ptr, size)

      // store the size of the metadata at the end of the bytecode
      mstore(ptr, size)
      ptr := add(ptr, 32)


      // store the total size of the data
      mstore(retVal, sub(ptr, start))
    }
  }

  /// @dev Calculates the VERC-20 address (via CREATE2) given `factoryAddress` and `args`.
  function _getAddressForVERC (address factoryAddress, bytes calldata args) internal returns (address retVal) {
    uint256 offset;
    assembly {
      offset := args.offset
    }
    bytes memory initCode = _getInitCodeForVERC(factoryAddress, offset, args.length);

    assembly {
      let initCodeHash := keccak256(add(initCode, 32), mload(initCode))
      let backupPtr := mload(64)

      mstore(84, initCodeHash)
      // salt
      mstore(52, 0)
      mstore(20, factoryAddress)
      mstore(0, 0xff)

      retVal := and(keccak256(31, 85), 0xffffffffffffffffffffffffffffffffffffffff)

      // restore important memory slots
      mstore(64, backupPtr)
      mstore(96, 0)
    }
  }
}
