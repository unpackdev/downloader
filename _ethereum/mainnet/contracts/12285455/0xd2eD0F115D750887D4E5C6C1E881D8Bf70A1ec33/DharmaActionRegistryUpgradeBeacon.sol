// SPDX-License-Identifier: MIT

pragma solidity 0.8.3; // optimization runs: 200, evm version: petersburg

/**
 * @title DharmaActionRegistryUpgradeBeacon
 * @author cf
 * @notice This contract holds the address of the current implementation for
 * the Dharma Action Registry contract and lets a controller update that address
 * in storage.
 * The contract has been forked and modified slightly from 0age's original implementation.
 */
contract DharmaActionRegistryUpgradeBeacon {
  // The implementation address is held in storage slot zero.
  address private _implementation;

  // The controller that can update the implementation an immutable.
  // The value is set at deployment in the constructor.
  address private immutable _UPGRADE_BEACON_CONTROLLER;

  constructor(address upgradeBeaconControllerAddress) {
    // Ensure upgrade-beacon-controller is specified
    require(upgradeBeaconControllerAddress != address(0), "Must specify an upgrade-beacon-controller address.");

    // Ensure that the upgrade-beacon-controller contract has code via extcodesize.
    uint256 upgradeBeaconControllerSize;
    assembly { upgradeBeaconControllerSize := extcodesize(upgradeBeaconControllerAddress) }
    require(upgradeBeaconControllerSize > 0, "upgrade-beacon-controller must have contract code.");

    _UPGRADE_BEACON_CONTROLLER = upgradeBeaconControllerAddress;
  }

  /**
   * @notice In the fallback function, allow only the controller to update the
   * implementation address - for all other callers, return the current address.
   * Note that this requires inline assembly, as Solidity fallback functions do
   * not natively take arguments or return values.
   */
  fallback() external {
    // Return implementation address for all callers other than the controller.
    if (msg.sender != _UPGRADE_BEACON_CONTROLLER) {
      // Load implementation from storage slot zero into memory and return it.
      assembly {
        mstore(0, sload(0))
        return(0, 32)
      }
    } else {
      // Set implementation - put first word in calldata in storage slot zero.
      assembly { sstore(0, calldataload(0)) }
    }
  }
}