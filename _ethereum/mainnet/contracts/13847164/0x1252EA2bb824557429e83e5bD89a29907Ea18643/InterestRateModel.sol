// SPDX-License-Identifier: UNLICENSED

// Copyright (c) WildCredit - All rights reserved
// https://twitter.com/WildCredit

pragma solidity 0.8.6;

import "IInterestRateModel.sol";
import "ILendingPair.sol";

import "Math.sol";
import "SafeOwnable.sol";

contract InterestRateModel is IInterestRateModel, SafeOwnable {

  // InterestRateModel can be re-deployed later
  uint private constant BLOCK_TIME = 13.2e18; // 13.2 seconds
  uint private constant LP_RATE = 50e18; // 50%

  // Per block
  uint public minRate;
  uint public lowRate;
  uint public highRate;
  uint public targetUtilization; // 80e18 = 80%

  event NewRates(uint minRate, uint lowRate, uint highRate);
  event NewTargetUtilization(uint value);

  constructor(
    uint _minRate,
    uint _lowRate,
    uint _highRate,
    uint _targetUtilization
  ) {

    setRates(_minRate, _lowRate, _highRate);
    setTargetUtilization(_targetUtilization);
  }

  function setRates(
    uint _minRate,
    uint _lowRate,
    uint _highRate
  ) public onlyOwner {

    require(_minRate < _lowRate,  "InterestRateModel: _minRate < _lowRate");
    require(_lowRate < _highRate, "InterestRateModel: _lowRate < highRate");

    minRate  = _timeRateToBlockRate(_minRate);
    lowRate  = _timeRateToBlockRate(_lowRate);
    highRate = _timeRateToBlockRate(_highRate);

    emit NewRates(_minRate, _lowRate, _highRate);
  }

  function setTargetUtilization(uint _value) public onlyOwner {
    require(_value > 0, "InterestRateModel: _value > 0");
    require(_value < 100e18, "InterestRateModel: _value < 100e18");
    targetUtilization = _value;
    emit NewTargetUtilization(_value);
  }

  // InterestRateModel can later be replaced for more granular fees per _pair
  function interestRatePerBlock(
    address _pair,
    address _token,
    uint    _totalSupply,
    uint    _totalDebt
  ) external view override returns(uint) {
    if (_totalSupply == 0 || _totalDebt == 0) { return minRate; }

    // Same as: (_totalDebt * 100e18 / _totalSupply) * 100e18 / targetUtilization
    uint utilization = _totalDebt * 100e18 * 100e18 / _totalSupply / targetUtilization;

    if (utilization < 100e18) {
      uint rate = lowRate * utilization / 100e18;
      return Math.max(rate, minRate);
    } else {
      utilization = 100e18 * ( _totalDebt - (_totalSupply * targetUtilization / 100e18) ) / (_totalSupply * (100e18 - targetUtilization) / 100e18);
      utilization = Math.min(utilization, 100e18);
      return lowRate + (highRate - lowRate) * utilization / 100e18;
    }
  }

  // Helper view function used only by the UI
  function utilizationRate(
    address _pair,
    address _token
  ) external view returns(uint) {
    ILendingPair pair = ILendingPair(_pair);
    uint totalSupply = pair.totalSupplyAmount(_token);
    uint totalDebt = pair.totalDebtAmount(_token);
    if (totalSupply == 0 || totalDebt == 0) { return 0; }
    return Math.min(totalDebt * 100e18 / totalSupply, 100e18);
  }

  // InterestRateModel can later be replaced for more granular fees per _pair
  function lpRate(address _pair, address _token) external view override returns(uint) {
    return LP_RATE;
  }

  // _uint is set as 1e18 = 1% (annual) and converted to the block rate
  function _timeRateToBlockRate(uint _uint) private view returns(uint) {
    return _uint * BLOCK_TIME / (365 * 86400 * 1e18);
  }
}
