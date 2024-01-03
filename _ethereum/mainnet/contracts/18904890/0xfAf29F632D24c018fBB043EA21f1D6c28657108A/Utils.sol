// SPDX-License-Identifier: MIT

pragma solidity 0.8.21;

/**
 * @title Utils
 * @custom:version v0.1.0
 * @notice Utilities used in ERC721Baseline.
 */
library Utils {
  /************************************************
   * ECDSA Utils
   ************************************************/

  /**
   * recover
   *
   * @notice Recovers the signer's address from a message digest `hash`, and the `signature`.
   * MIT Licensed, (c) 2022-present Solady.
   */
  function recover(bytes32 hash, bytes memory signature) internal view returns (address result) {
    /// @solidity memory-safe-assembly
    assembly {
      result := 1
      let m := mload(0x40) // Cache the free memory pointer.
      // prettier-ignore
      for {} 1 {} {
        mstore(0x00, hash)
        mstore(0x40, mload(add(signature, 0x20))) // `r`.
        if eq(mload(signature), 64) {
          let vs := mload(add(signature, 0x40))
          mstore(0x20, add(shr(255, vs), 27)) // `v`.
          mstore(0x60, shr(1, shl(1, vs))) // `s`.
          break
        }
        if eq(mload(signature), 65) {
          mstore(0x20, byte(0, mload(add(signature, 0x60)))) // `v`.
          mstore(0x60, mload(add(signature, 0x40))) // `s`.
          break
        }
        result := 0
        break
      }
      result := mload(
        staticcall(
          gas(), // Amount of gas left for the transaction.
          result, // Address of `ecrecover`.
          0x00, // Start of input.
          0x80, // Size of input.
          0x01, // Start of output.
          0x20 // Size of output.
        )
      )
      // `returndatasize()` will be `0x20` upon success, and `0x00` otherwise.
      if iszero(returndatasize()) {
        mstore(0x00, 0x8baa579f) // `InvalidSignature()`.
        revert(0x1c, 0x04)
      }
      mstore(0x60, 0) // Restore the zero slot.
      mstore(0x40, m) // Restore the free memory pointer.
    }
  }

  /**
   * recoverCalldata
   *
   * @notice Recovers the signer's address from a message digest `hash`, and the `signature`.
   * MIT Licensed, (c) 2022-present Solady.
   */
  function recoverCalldata(
    bytes32 hash,
    bytes calldata signature
  ) internal view returns (address result) {
    /// @solidity memory-safe-assembly
    assembly {
      result := 1
      let m := mload(0x40) // Cache the free memory pointer.
      mstore(0x00, hash)
      // prettier-ignore
      for {} 1 {} {
        if eq(signature.length, 64) {
          let vs := calldataload(add(signature.offset, 0x20))
          mstore(0x20, add(shr(255, vs), 27)) // `v`.
          mstore(0x40, calldataload(signature.offset)) // `r`.
          mstore(0x60, shr(1, shl(1, vs))) // `s`.
          break
        }
        if eq(signature.length, 65) {
          mstore(0x20, byte(0, calldataload(add(signature.offset, 0x40)))) // `v`.
          calldatacopy(0x40, signature.offset, 0x40) // Copy `r` and `s`.
          break
        }
        result := 0
        break
      }
      result := mload(
        staticcall(
          gas(), // Amount of gas left for the transaction.
          result, // Address of `ecrecover`.
          0x00, // Start of input.
          0x80, // Size of input.
          0x01, // Start of output.
          0x20 // Size of output.
        )
      )
      // `returndatasize()` will be `0x20` upon success, and `0x00` otherwise.
      if iszero(returndatasize()) {
        mstore(0x00, 0x8baa579f) // `InvalidSignature()`.
        revert(0x1c, 0x04)
      }
      mstore(0x60, 0) // Restore the zero slot.
      mstore(0x40, m) // Restore the free memory pointer.
    }
  }

  /**
   * toEthSignedMessageHash
   *
   * @dev Returns an Ethereum Signed Message, created from a `hash`.
   * This produces a hash corresponding to the one signed with the
   * [`eth_sign`](https://eth.wiki/json-rpc/API#eth_sign)
   * JSON-RPC method as part of EIP-191.
   * MIT Licensed, (c) 2022-present Solady.
   */
  function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32 result) {
    /// @solidity memory-safe-assembly
    assembly {
      mstore(0x20, hash) // Store into scratch space for keccak256.
      mstore(0x00, "\x00\x00\x00\x00\x19Ethereum Signed Message:\n32") // 28 bytes.
      result := keccak256(0x04, 0x3c) // `32 * 2 - (32 - 28) = 60 = 0x3c`.
    }
  }


  /************************************************
   * String Utils
   ************************************************/

  /**
   * @notice toString.
   * MIT Licensed, (c) 2022-present OpenZeppelin.
   */
  function toString(uint256 value) internal pure returns (string memory) {
    unchecked {
      uint256 length = log10(value) + 1;
      string memory buffer = new string(length);
      uint256 ptr;
      /// @solidity memory-safe-assembly
      assembly {
        ptr := add(buffer, add(32, length))
      }
      while (true) {
        ptr--;
        /// @solidity memory-safe-assembly
        assembly {
          mstore8(ptr, byte(mod(value, 10), "0123456789abcdef"))
        }
        value /= 10;
        if (value == 0) break;
      }
      return buffer;
    }
  }

  /**
   * @dev Return the log in base 10 of a positive value rounded towards zero.
   * Returns 0 if given 0.
   */
  function log10(uint256 value) internal pure returns (uint256) {
    uint256 result = 0;
    unchecked {
      if (value >= 10 ** 64) {
        value /= 10 ** 64;
        result += 64;
      }
      if (value >= 10 ** 32) {
        value /= 10 ** 32;
        result += 32;
      }
      if (value >= 10 ** 16) {
        value /= 10 ** 16;
        result += 16;
      }
      if (value >= 10 ** 8) {
        value /= 10 ** 8;
        result += 8;
      }
      if (value >= 10 ** 4) {
        value /= 10 ** 4;
        result += 4;
      }
      if (value >= 10 ** 2) {
        value /= 10 ** 2;
        result += 2;
      }
      if (value >= 10 ** 1) {
        result += 1;
      }
    }
    return result;
  }
}
