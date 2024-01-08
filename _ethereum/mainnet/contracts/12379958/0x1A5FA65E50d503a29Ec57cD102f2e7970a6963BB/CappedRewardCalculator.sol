// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

// curve definition:
// https://www.desmos.com/calculator/8xyyuznuz3
//
// integral:
// https://www.wolframalpha.com/input/?i=integrate%5B-1%2B1.01*10%5E%282-0.02*x%29%2C+x%5D

import "./CappedRewardCalculator.sol";

contract TestCappedRewardCalculator is CappedRewardCalculator {
  constructor(
    uint _startDate,
    uint _endDate,
    uint _cap
  ) CappedRewardCalculator(_startDate, _endDate, _cap) { }

  function testToPeriodPercents(uint _start, uint _end) public view returns (uint, uint) {
    return toPeriodPercents(_start, _end);
  }

  function testTruncatePeriod(uint _start, uint _end) public view returns (uint, uint) {
    return truncatePeriod(_start, _end);
  }

  function testCurvePercentage(uint _start, uint _end) public pure returns (uint) {
    return curvePercentage(_start, _end);
  }

  function testIntegralAtPoint(uint x) public pure returns (int) {
    return integralAtPoint(x);
  }
}
