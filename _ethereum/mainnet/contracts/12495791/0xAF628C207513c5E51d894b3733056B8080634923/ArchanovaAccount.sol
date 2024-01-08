// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

/**
 * @title Archanova account
 *
 * @author Stanisław Głogowski <stan@pillarproject.io>
 */
abstract contract ArchanovaAccount {
  struct Device {
    bool isOwner;
    bool exists;
    bool existed;
  }

  mapping(address => Device) public devices;

  // events

  event DeviceAdded(
    address device,
    bool isOwner
  );

  event DeviceRemoved(
    address device
  );

  event TransactionExecuted(
    address recipient,
    uint256 value,
    bytes data,
    bytes response
  );

  // external functions

  function addDevice(
    address device,
    bool isOwner
  )
    virtual
    external;

  function removeDevice(
    address device
  )
    virtual
    external;

  function executeTransaction(
    address payable recipient,
    uint256 value,
    bytes calldata data
  )
    virtual
    external
    returns (bytes memory);
}
