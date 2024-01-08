// SPDX-License-Identifier: Unlicense
pragma solidity >=0.7.6;

import "./HabitatBase.sol";

/// @notice Functionality for Habitat Modules
// Audit-1: ok
contract HabitatModule is HabitatBase {
  event ModuleRegistered(address indexed contractAddress, bytes metadata);

  /// @dev Verifies that the bytecode at `contractAddress` can not
  /// introduce side effects on the rollup at will.
  /// The convention for Modules is that they handle a known set of callbacks
  /// without handling their own state. Thus, opcodes for state handling etc are not allowed.
  function _verifyModule (address contractAddress) internal view returns (bytes32 codehash) {
    assembly {
      function doRevert () {
        // revert with non-zero returndata to signal we are not out of gas
        revert(0, 1)
      }

      let size := extcodesize(contractAddress)
      if iszero(size) {
        doRevert()
      }

      let terminatedByOpcode := 0
      let ptr := mload(64)
      let end := add(ptr, size)
      // copy the bytecode into memory
      extcodecopy(contractAddress, ptr, 0, size)
      // and hash it
      codehash := keccak256(ptr, size)

      // verify opcodes
      for { } lt(ptr, end) { ptr := add(ptr, 1) } {
        // this is used to detect metadata from the solidity compiler
        // at the end of the bytecode
        // this most likely doesn't work if strings or other data are appended
        // at the end of the bytecode,
        // but works if the developer follows some conventions.
        let terminatedByPreviousOpcode := terminatedByOpcode
        terminatedByOpcode := 0
        let opcode := byte(0, mload(ptr))

        // PUSH opcodes
        if and(gt(opcode, 95), lt(opcode, 128)) {
          let len := sub(opcode, 95)
          ptr := add(ptr, len)
          continue
        }

        // DUPx and SWAPx
        if and(gt(opcode, 127), lt(opcode, 160)) {
          continue
        }

        // everything from 0x0 to 0x20 (inclusive)
        if lt(opcode, 0x21) {
          // in theory, opcode 0x0 (STOP) also terminates execution
          // but we will ignore this one
          continue
        }

        // another set of allowed opcodes
        switch opcode
        // CALLVALUE
        case 0x34 {}
        // CALLDATALOAD
        case 0x35 {}
        // CALLDATASIZE
        case 0x36 {}
        // CALLDATACOPY
        case 0x37 {}
        // CODESIZE
        case 0x38 {}
        // CODECOPY
        case 0x39 {}
        // POP
        case 0x50 {}
        // MLOAD
        case 0x51 {}
        // MSTORE
        case 0x52 {}
        // MSTORE8
        case 0x53 {}
        // JUMP
        case 0x56 {}
        // JUMPI
        case 0x57 {}
        // PC
        case 0x58 {}
        // MSIZE
        case 0x59 {}
        // JUMPDEST
        case 0x5b {}
        // RETURN
        case 0xf3 {
          terminatedByOpcode := 1
        }
        // REVERT
        case 0xfd {
          terminatedByOpcode := 1
        }
        // INVALID
        case 0xfe {
          terminatedByOpcode := 1
        }
        default {
          // we fall through if the previous opcode terminates execution
          if iszero(terminatedByPreviousOpcode) {
            // everything else is not allowed
            doRevert()
          }
        }
      }
    }
  }

  /// @notice Register a module to be used for Habitat Vaults (Treasuries).
  /// The bytecode at `contractAddress` must apply to some conventions, see `_verifyModule`.
  /// @param _type Must be `1`.
  /// @param contractAddress of the module.
  /// @param codeHash of the bytecode @ `contractAddress`
  function registerModule (
    uint256 _type,
    address contractAddress,
    bytes32 codeHash,
    bytes calldata /*metadata*/) external
  {
    if (_type != 1) {
      revert();
    }

    _createBlockMessage();

    // verify the contract code and returns the keccak256(bytecode) (reverts if invalid)
    require(_verifyModule(contractAddress) == codeHash && codeHash != 0);
  }

  /// @notice Layer 2 callback for blocks created with `_createBlockMessage`.
  /// Used for module registration (type = 1).
  function onCustomBlockBeacon (bytes memory data) external {
    HabitatBase._commonChecks();

    uint256 _type;
    assembly {
      _type := calldataload(68)
    }

    if (_type == 1) {
      (, address contractAddress, bytes32 codeHash, bytes memory metadata) =
        abi.decode(data, (uint256, address, bytes32, bytes));

      // same contract (address) should not be submitted twice
      require(HabitatBase._getStorage(_MODULE_HASH_KEY(contractAddress)) == 0, 'OSM1');

      HabitatBase._setStorage(_MODULE_HASH_KEY(contractAddress), codeHash);

      if (_shouldEmitEvents()) {
        emit ModuleRegistered(contractAddress, metadata);
      }
    }
  }
}
