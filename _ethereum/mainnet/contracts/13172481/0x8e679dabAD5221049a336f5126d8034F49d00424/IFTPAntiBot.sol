// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface IFTPAntiBot {
  function scanAddress(
    address _address,
    address _safeAddress,
    address _origin
  ) external returns (bool);

  function registerBlock(address _recipient, address _sender) external;
}
