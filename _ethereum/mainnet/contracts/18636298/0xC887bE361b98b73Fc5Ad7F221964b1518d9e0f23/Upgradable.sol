// SPDX-License-Identifier: MIT
pragma solidity =0.8.20;
pragma abicoder v2;

/**
 * This is an abstract contract implementing updates to the EIP-1967
 * implementation slot, as used by proxy.
 */
abstract contract Upgradable {
  // EIP-1967 defines implementation slot as uint256(keccak256('eip1967.proxy.implementation')) - 1
  bytes32 constant EIP_1967_SLOT = hex'360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc';

  // Storage - a set of logic contracts already migrated to, used to prevent duplicate updates.
  mapping(address => bool) migratedTo;

  /**
   * A modifier that enforces that the method it's attached to gets invoked just
   * once during the specific logic contract tenure. It is used to enforce that
   * the migrate() method that is run right after the upgrade takes place cannot
   * be run anymore by the external caller.
   */
  modifier onlyOnce() {
    address implementationAddress;

    assembly {
      implementationAddress := sload(EIP_1967_SLOT)
    }

    require(!migratedTo[implementationAddress], "This should only be called once");
    migratedTo[implementationAddress] = true;

    _;
  }

  /**
   * Virtual logic migration method - intended to be called right after the
   * wallet is upgraded to a new logic version.
   *
   * @param previousImplementation the logic contract address before the upgrade
   * @return success a flag which is true if the migration was succesful
   */
  function migrate(address previousImplementation) virtual external returns (bool);

  /**
   * Upgrade implementation proper. Overwrites the implementation slot and runs migrate().
   *
   * @param newImplementation new logic contract address
   */
  function _upgrade(address newImplementation) internal {
    address previousImplementation;

    // Update the EIP-1967 implementation slot
    assembly {
      previousImplementation := sload(EIP_1967_SLOT)
      sstore(EIP_1967_SLOT, newImplementation)
    }

    // Run the migrate() method via chained DELEGATECALL to self
    (bool success, bytes memory result) = newImplementation.delegatecall(abi.encodeCall(Upgradable.migrate, (previousImplementation)));
    require(success, "migrate() call reverted");
    require(abi.decode(result, (bool)), "migrate() did not return true");
  }
}
