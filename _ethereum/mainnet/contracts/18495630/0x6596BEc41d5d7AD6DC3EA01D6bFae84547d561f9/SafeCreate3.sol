// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.18;

import "./Bytes32AddressLib.sol";
import "./CREATE3.sol";

/// @title SafeCreate3
/// @notice Variant of solmate's CREATE3 with front running protection
/// @dev Since `deploy(...)` is always called from the same address (i.e. the Factory),
/// NFT address registration could technically be front run. To mitigate this, we add
/// at the begining of the bytecode the address of the account that creates it.
/// e.g.: PUSH20 `createdBy`. This operation doesn't do anything other than prevent
/// front running. The rest of the library is practically identical to solmate's CREATE3.
library SafeCreate3 {
  using Bytes32AddressLib for bytes32;

  function deploy(
    bytes32 salt,
    address createdBy,
    bytes memory creationCode,
    uint256 value
  ) internal returns (address deployed) {
    bytes memory proxyChildBytecode = getBytecode(createdBy);

    address proxy;
    /// @solidity memory-safe-assembly
    assembly {
      // Deploy a new contract with our pre-made bytecode via CREATE2.
      // We start 32 bytes into the code to avoid copying the byte length.
      proxy := create2(0, add(proxyChildBytecode, 32), mload(proxyChildBytecode), salt)
    }
    require(proxy != address(0), "DEPLOYMENT_FAILED");

    deployed = getDeployed(salt, createdBy);
    (bool success, ) = proxy.call{value: value}(creationCode);
    require(success && deployed.code.length != 0, "INITIALIZATION_FAILED");
  }

  function getDeployed(bytes32 salt, address createdBy) internal view returns (address) {
    address proxy = keccak256(
      abi.encodePacked(
        // Prefix:
        bytes1(0xFF),
        // Creator:
        address(this),
        // Salt:
        salt,
        // Bytecode hash:
        getBytecodeHash(createdBy)
      )
    ).fromLast20Bytes();

    return
      keccak256(
        abi.encodePacked(
          // 0xd6 = 0xc0 (short RLP prefix) + 0x16 (length of: 0x94 ++ proxy ++ 0x01)
          // 0x94 = 0x80 + 0x14 (0x14 = the length of an address, 20 bytes, in hex)
          hex"d6_94",
          proxy,
          hex"01" // Nonce of the proxy contract (1)
        )
      ).fromLast20Bytes();
  }

  //--------------------------------------------------------------------------------//
  // Opcode     | Opcode + Arguments    | Description      | Stack View             //
  //--------------------------------------------------------------------------------//
  // 0x73       |  0x73 createdBy       | PUSH20           | createdBy              //
  // 0x50       |  0x50                 | POP              |                        //
  // ... See CREATE3's bytecode
  //
  /// @notice Adds "PUSH20 `createdBy`" and POP to solmate's CREATE3 deploy bytecode
  /// to prevent frontrunning.
  /// @param createdBy Address of the account that creates the smart contract
  function getBytecode(address createdBy) internal pure returns (bytes memory) {
    return abi.encodePacked(hex"73", createdBy, hex"50", CREATE3.PROXY_BYTECODE);
  }

  function getBytecodeHash(address createdBy) internal pure returns (bytes32) {
    return keccak256(getBytecode(createdBy));
  }
}
