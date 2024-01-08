// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

/// @title Calculates rewards based on an initial downward curve period, and a second constant period
/// @notice Calculation of the reward is based on a few rules:
///   * start and end date of the staking period (the earlier you enter, and
///     the longer you stay, the greater your overall reward)
///
///   * At each point, the the current reward is described by a downward curve
///     (https://www.desmos.com/calculator/dz8vk1urep)
///
///   * Computing your total reward (which is done upfront in order to lock and
///     guarantee your reward) means computing the integral of the curve period from
///     your enter date until the end
///     (https://www.wolframalpha.com/input/?i=integrate+%28100-x%29%5E2)
///
///   * This integral is the one being calculated in the `integralAtPoint` function
///
///   * Besides this rule, rewards are also capped by a maximum percentage
///     provided at contract instantiation time (a cap of 40 means your maximum
///     possible reward is 40% of your initial stake
///
/// @author Miguel Palhas <miguel@subvisual.co>
contract CappedRewardCalculator {
  /// @notice start of the staking period
  uint public immutable startDate;
  /// @notice end of the staking period
  uint public immutable endDate;
  /// @notice Reward cap for curve period
  uint public immutable cap;

  uint constant private year = 365 days;
  uint constant private day = 1 days;
  uint private constant mul = 1000000;

  /// @notice constructor
  /// @param _start The start timestamp for staking
  /// @param _start The end timestamp for staking
  /// @param _cap The cap percentage of the reward (40 == maximum of 40% of your initial stake)
  constructor(
    uint _start,
    uint _end,
    uint _cap
  ) {
    require(block.timestamp <= _start, "CappedRewardCalculator: start date must be in the future");
    require(
      _start < _end,
      "CappedRewardCalculator: end date must be after start date"
    );

    require(_cap > 0, "CappedRewardCalculator: curve cap cannot be 0");

    startDate = _start;
    endDate = _end;
    cap = _cap;
  }

  /// @notice Given a timestamp range and an amount, calculates the expected nominal return
  /// @param _start The start timestamp to consider
  /// @param _end The end timestamp to consider
  /// @param _amount The amount to stake
  /// @return The nominal amount of the reward
  function calculateReward(
    uint _start,
    uint _end,
    uint _amount
  ) public view returns (uint) {
    (uint start, uint end) = truncatePeriod(_start, _end);
    (uint startPercent, uint endPercent) = toPeriodPercents(start, end);

    uint percentage = curvePercentage(startPercent, endPercent);

    uint reward = _amount * cap * percentage / (mul * 100);

    return reward;
  }

  /// @notice Estimates the current offered APY
  /// @return The estimated APY (40 == 40%)
  function currentAPY() public view returns (uint) {
    uint amount = 100 ether;
    uint today = block.timestamp;

    if (today < startDate) {
      today = startDate;
    }

    uint todayReward = calculateReward(startDate, today, amount);

    uint tomorrow = today + day;
    uint tomorrowReward = calculateReward(startDate, tomorrow, amount);

    uint delta = tomorrowReward - todayReward;
    uint apy = delta * 365 * 100 / amount;

    return apy;
  }

  function toPeriodPercents(
    uint _start,
    uint _end
  ) internal view returns (uint, uint) {
    uint totalDuration = endDate - startDate;

    if (totalDuration == 0) {
      return (0, mul);
    }

    uint startPercent = (_start - startDate) * mul / totalDuration;
    uint endPercent = (_end - startDate) * mul / totalDuration;

    return (startPercent, endPercent);
  }

  function truncatePeriod(
    uint _start,
    uint _end
  ) internal view returns (uint, uint) {
    if (_end <= startDate || _start >= endDate) {
      return (startDate, startDate);
    }

    uint start = _start < startDate ? startDate : _start;
    uint end = _end > endDate ? endDate : _end;

    return (start, end);
  }

  function curvePercentage(uint _start, uint _end) internal pure returns (uint) {
    int maxArea = integralAtPoint(mul) - integralAtPoint(0);
    int actualArea = integralAtPoint(_end) - integralAtPoint(_start);

    uint ratio = uint(actualArea * int(mul) / maxArea);

    return ratio;
  }


  function integralAtPoint(uint _x) internal pure returns (int) {
    int x = int(_x);
    int p1 = ((x - int(mul)) ** 3) / (3 * int(mul));

    return p1;
  }
}
