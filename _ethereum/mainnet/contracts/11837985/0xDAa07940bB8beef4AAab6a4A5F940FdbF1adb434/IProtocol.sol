// SPDX-License-Identifier: No License

pragma solidity ^0.8.0;

interface IProtocol {
  function coverMap(address _collateral, uint48 _expirationTimestamp) external view returns (address);
  function addCover(address _collateral, uint48 _timestamp, uint256 _amount) external returns (bool);
}