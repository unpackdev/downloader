// SPDX-License-Identifier: MIT

pragma solidity 0.8.3;

interface IDharmaActionRegistry {
  function initialize() external;
}

/**
 * @title DharmaActionRegistry
 * @author cf
 * @notice This contract delegates all logic, to an implementation contract
 * whose address is held by the upgrade-beacon specified at initialization.
 */
contract DharmaActionRegistry {
  // Declare upgrade beacon address as a immutable (i.e. not in contract storage).
  // The value is set at deployment in the constructor.
  address immutable _UPGRADE_BEACON;

  /**
   * @notice In the constructor, set the upgrade-beacon address.
   * implementation set on the upgrade beacon, supplying initialization calldata
   * as a constructor argument. The deployment will revert and pass along the
   * revert reason in the event that this initialization delegatecall reverts.
   * @param upgradeBeaconAddress address to set as the upgrade-beacon that
   * holds the implementation contract
   */
  constructor(address upgradeBeaconAddress) {
    // Ensure upgrade-beacon is specified
    require(upgradeBeaconAddress != address(0), "Must specify an upgrade-beacon address.");

    // Ensure that the upgrade-beacon contract has code via extcodesize.
    uint256 upgradeBeaconSize;
    assembly { upgradeBeaconSize := extcodesize(upgradeBeaconAddress) }
    require(upgradeBeaconSize > 0, "upgrade-beacon must have contract code.");

    _UPGRADE_BEACON = upgradeBeaconAddress;

    // retrieve implementation to initialize - this is the same logic as _implementation
    (bool ok, bytes memory returnData) = upgradeBeaconAddress.staticcall("");

    // Revert and pass along revert message if call to upgrade beacon reverts.
    if(!ok) {
      assembly {
        returndatacopy(0, 0, returndatasize())
        revert(0, returndatasize())
      }
    }

    // Get the implementation to the address returned from the upgrade beacon.
    address implementation = abi.decode(returnData, (address));

    // Delegatecall into the implementation, supplying initialization calldata.
    (ok, ) = implementation.delegatecall(abi.encodeWithSelector(IDharmaActionRegistry.initialize.selector));

    // Revert and include revert data if delegatecall to implementation reverts.
    if (!ok) {
      assembly {
        returndatacopy(0, 0, returndatasize())
        revert(0, returndatasize())
      }
    }
  }

  /**
   * @notice In the fallback, delegate execution to the implementation set on
   * the upgrade beacon.
   */
  fallback() external {
    // Delegate execution to implementation contract provided by upgrade beacon.
    _delegate(_implementation());
  }

  /**
   * @notice Private view function to get the current implementation from the
   * upgrade beacon. This is accomplished via a staticcall to the beacon with no
   * data, and the beacon will return an abi-encoded implementation address.
   * @return implementation address of the implementation.
   */
  function _implementation() private view returns (address implementation) {
    // Get the current implementation address from the upgrade beacon.
    (bool ok, bytes memory returnData) = _UPGRADE_BEACON.staticcall("");

    // Revert and pass along revert message if call to upgrade beacon reverts.
    require(ok, string(returnData));

    // Set the implementation to the address returned from the upgrade beacon.
    implementation = abi.decode(returnData, (address));
  }

  /**
   * @notice Private function that delegates execution to an implementation
   * contract. This is a low level function that doesn't return to its internal
   * call site. It will return whatever is returned by the implementation to the
   * external caller, reverting and returning the revert data if implementation
   * reverts.
   * @param implementation address to delegate.
   */
  function _delegate(address implementation) private {
    assembly {
    // Copy msg.data. We take full control of memory in this inline assembly
    // block because it will not return to Solidity code. We overwrite the
    // Solidity scratch pad at memory position 0.
      calldatacopy(0, 0, calldatasize())

    // Delegatecall to the implementation, supplying calldata and gas.
    // Out and outsize are set to zero - instead, use the return buffer.
      let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

    // Copy the returned data from the return buffer.
      returndatacopy(0, 0, returndatasize())

      switch result
      // Delegatecall returns 0 on error.
      case 0 { revert(0, returndatasize()) }
      default { return(0, returndatasize()) }
    }
  }
}