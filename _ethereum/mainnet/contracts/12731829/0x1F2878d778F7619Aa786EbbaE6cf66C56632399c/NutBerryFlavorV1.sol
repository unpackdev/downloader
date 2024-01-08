// SPDX-License-Identifier: Unlicense
pragma solidity >=0.7.6;

import "./NutBerryTokenBridge.sol";

/// @notice Composition of EVM enabled, application specific rollup.
/// Version 1
// Audit-1: ok
contract NutBerryFlavorV1 is NutBerryTokenBridge {
  /// @dev Returns the storage value for `key`.
  /// Verifies access on L1(inside challenge) and reverts if no witness for this key exists.
  function _sload (uint256 key) internal override returns (uint256 ret) {
    assembly {
      switch origin()
      case 0 {
        // nothing special needs to be done on layer 2
        ret := sload(key)
      }
      default {
        // on layer 1:
        // iterates over a list of keys (32 bytes).
        // if the key is found, then a valid witness was provided in a challenge,
        // otherwise we revert here :grumpy_cat
        //
        // < usual calldata... >
        // < read witnesses... - each 32 bytes >
        // < # of witness elements - 32 bytes>
        // < write witnesses - each 32 bytes >
        // < # of witness elements - 32 bytes >

        let end := sub(calldatasize(), 32)
        end := sub(sub(end, 32), mul(calldataload(end), 32))
        let nKeys := calldataload(end)
        let start := sub(end, mul(nKeys, 32))
        let found := 0

        for { let i := 0 } lt(i, nKeys) { i := add(i, 1) } {
          let ptr := add(start, mul(i, 32))
          if eq(calldataload(ptr), key) {
            found := 1
            break
          }
        }

        if iszero(found) {
          revert(0, 0)
        }

        ret := sload(key)
      }
    }
  }

  /// @dev Stores `value` with `key`.
  /// Verifies access on L1(inside challenge) and reverts if no witness for this key exists.
  function _sstore (uint256 key, uint256 value) internal override {
    assembly {
      switch origin()
      case 0 {
        // nothing to do on layer 2
        sstore(key, value)
      }
      default {
        // layer 1
        // iterates over a list of keys
        // if the key is found, then a valid witness was provided in a challenge,
        // otherwise: revert
        //
        // < usual calldata... >
        // < read witnesses... - each 32 bytes >
        // < # of witness elements - 32 bytes>
        // < write witnesses - each 32 bytes >
        // < # of witness elements - 32 bytes >
        let end := sub(calldatasize(), 32)
        let nKeys := calldataload(end)
        let start := sub(end, mul(nKeys, 32))
        let found := 0

        for { let i := 0 } lt(i, nKeys) { i := add(i, 1) } {
          let ptr := add(start, mul(i, 32))
          if eq(calldataload(ptr), key) {
            // this is used to verify that all provided (write) witnesses
            // was indeed written to.
            // rollup transactions must never write to this slot
            let SPECIAL_STORAGE_SLOT := 0xabcd
            let bitmask := sload(SPECIAL_STORAGE_SLOT)

            sstore(SPECIAL_STORAGE_SLOT, and( bitmask, not(shl(i, 1)) ))
            found := 1
            break
          }
        }

        if iszero(found) {
          revert(0, 0)
        }

        sstore(key, value)
      }
    }
  }

  /// @dev Returns the timestamp (in seconds) of the block this transaction is part of.
  /// It returns the equivalent of `~~(Date.now() / 1000)` for a not yet submitted block - (L2).
  function _getTime () internal virtual returns (uint256 ret) {
    assembly {
      switch origin()
      case 0 {
        // layer 2: return the equivalent of `~~(Date.now() / 1000)`
        ret := timestamp()
      }
      default {
        // load the timestamp from calldata on layer 1.
        // the setup is done inside a challenge
        //
        // < usual calldata... >
        // < 32 bytes timestamp >
        // < read witnesses... - each 32 bytes >
        // < # of witness elements - 32 bytes>
        // < write witnesses - each 32 bytes >
        // < # of witness elements - 32 bytes >
        let ptr := sub(calldatasize(), 32)
        // load the length of nElements and sub
        ptr := sub(ptr, mul(32, calldataload(ptr)))
        // points to the start of `write witnesses`
        ptr := sub(ptr, 32)
        // points at `# read witnesses` and subtracts
        ptr := sub(ptr, mul(32, calldataload(ptr)))
        // at the start of `read witnesses` sub 32 again
        ptr := sub(ptr, 32)
        // finish line
        ret := calldataload(ptr)
      }
    }
  }

  /// @dev Emits a log event that signals the l2 node
  /// that this transactions has to be submitted in a block before `timeSeconds`.
  function _emitTransactionDeadline (uint256 timeSeconds) internal {
    assembly {
      // only if we are off-chain
      if iszero(origin()) {
        log2(0, 0, 3, timeSeconds)
      }
    }
  }

  /// @dev Finalize solution for `blockNumber` and move to the next block.
  /// Calldata(data appended at the end) contains a blob of key:value pairs that go into storage.
  /// If this functions reverts, then the block can only be finalised by a call to `challenge`.
  /// - Should only be callable from self.
  /// - Supports relative value(delta) and absolute storage updates
  /// calldata layout:
  /// < 4 byte function sig >
  /// < 32 byte blockNumber >
  /// < 32 byte submitted solution hash >
  /// < witness data >
  function onFinalizeSolution (uint256 /*blockNumber*/, bytes32 hash) external {
    // all power to the core protocol
    require(msg.sender == address(this));

    assembly {
      // the actual witness data should be appended after the function arguments.
      let witnessDataSize := sub(calldatasize(), 68)

      calldatacopy(0, 68, witnessDataSize)
      // hash the key:value blob
      let solutionHash := keccak256(0, witnessDataSize)

      // the hash of the witness should match
      if iszero(eq(solutionHash, hash)) {
        revert(0, 0)
      }

      // update contract storage
      for { let ptr := 68 } lt(ptr, calldatasize()) { } {
        // first byte; 0 = abs, 1 = delta
        let storageType := byte(0, calldataload(ptr))
        ptr := add(ptr, 1)

        // first 32 bytes is the key
        let key := calldataload(ptr)
        ptr := add(ptr, 32)

        // second 32 bytes the value
        let val := calldataload(ptr)
        ptr := add(ptr, 32)

        switch storageType
        case 0 {
          // the value is absolute
          sstore(key, val)
        }
        default {
          // the value is actually a delta
          sstore(key, add(sload(key), val))
        }
      }
      stop()
    }
  }
}
