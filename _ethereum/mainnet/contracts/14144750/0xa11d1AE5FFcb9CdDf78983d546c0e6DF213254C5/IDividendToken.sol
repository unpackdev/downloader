// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

/**
 * @title DividendBasic
 * @dev DividendToken interface
 */
interface IDividendToken {
  function totalDividendSupply() external view returns (uint256); 
  function addToDividendSupply(address _from, uint256 value) external returns (bool);
  function updateDividendBlacklist(address _address, bool isBlacklisted) external;

  event DividendBlacklistUpdated(address indexed _newAddress, bool isBlacklisted);
  event DividendTimeStampInitialized(address indexed _who, uint timestamp, uint currentPeriodNumber);
  event DividendCollected(address indexed _by, uint256 value, uint dividendPeriods);
  event DividendSent(address indexed _to, uint256 value, uint dividendPeriods);
  event BurnToDividend(address indexed _from, uint256 value);
}
