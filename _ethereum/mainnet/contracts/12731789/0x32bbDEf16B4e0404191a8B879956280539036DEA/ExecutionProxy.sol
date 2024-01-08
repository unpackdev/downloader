// SPDX-License-Identifier: Unlicense
pragma solidity >=0.7.6;

import "./MetaProxyFactory.sol";
import "./IBridge.sol";

/// @notice This contract verifies execution permits and is meant to be used for L1 governance.
/// A new proxy can be created with `createProxy`, to be used for governance.
// Audit-1: ok
contract ExecutionProxy is MetaProxyFactory {
  /// @notice keeps track of already executed permits
  mapping (bytes32 => bool) public executed;

  event ProxyCreated(address indexed bridge, address indexed vault, address proxy);

  /// @notice Returns the metadata of this (MetaProxy) contract.
  /// Only relevant with contracts created via the MetaProxy.
  /// @dev This function is aimed to be invoked with- & without a call.
  function getMetadata () public pure returns (
    address bridge,
    address vault
  ) {
    assembly {
      // calldata layout:
      // [ arbitrary data... ] [ metadata... ] [ size of metadata 32 bytes ]
      bridge := calldataload(sub(calldatasize(), 96))
      vault := calldataload(sub(calldatasize(), 64))
    }
  }

  /// @notice MetaProxy construction via calldata.
  /// @param bridge is the address of the habitat rollup
  /// @param vault is the L2 vault used for governance.
  function createProxy (address bridge, address vault) external returns (address addr) {
    addr = MetaProxyFactory._metaProxyFromCalldata();
    emit ProxyCreated(bridge, vault, addr);
  }

  /// @notice Executes a set of contract calls `actions` if there is a valid
  /// permit on the rollup bridge for `proposalId` and `actions`.
  function execute (bytes32 proposalId, bytes memory actions) external {
    (address bridge, address vault) = getMetadata();

    require(executed[proposalId] == false, 'already executed');
    require(
      IBridge(bridge).executionPermit(vault, proposalId) == keccak256(actions),
      'wrong permit'
    );

    // mark it as executed
    executed[proposalId] = true;
    // execute
    assembly {
      // Note: we use `callvalue()` instead of `0`
      let ptr := add(actions, 32)
      let max := add(ptr, mload(actions))

      for { } lt(ptr, max) { } {
        let addr := mload(ptr)
        ptr := add(ptr, 32)
        let size := mload(ptr)
        ptr := add(ptr, 32)

        let success := call(gas(), addr, callvalue(), ptr, size, callvalue(), callvalue())
        if iszero(success) {
          // failed, copy the error
          returndatacopy(callvalue(), callvalue(), returndatasize())
          revert(callvalue(), returndatasize())
        }
        ptr := add(ptr, size)
      }
    }
  }
}
