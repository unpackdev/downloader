// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IFixedPeriodDeployer {
  function deployFixedPeriod(
    string memory _name,
    string memory _symbol,
    string memory _bURI,
    address _timelock,
    address _erc20,
    address payable _platform,
    address payable _receivingAddress,
    uint256 _initialRate,
    uint256 _startTime,
    uint256 _termOfValidity,
    uint256 _maxSupply,
    uint256 _platformRate
  ) external returns (address);
}
