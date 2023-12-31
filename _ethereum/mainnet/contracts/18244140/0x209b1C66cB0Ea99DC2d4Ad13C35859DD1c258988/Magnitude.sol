// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "./Utils.sol";

contract Magnitude is Utils {
  uint256 constant internal X_OPTIONS = THREE;
  function _computeDayMagnitude(
    uint256 limit, uint256 method, uint256 x,
    uint256 today, // today
    uint256 lockedDay, // lockedDay
    uint256 stakedDays
  ) internal pure returns(uint256 newMethod, uint256 numDays) {
    newMethod = method;
    unchecked {
      if (method < THREE) {
        if (method == ONE) {
          // useful when you want the next stake start to be
          // entirely different and simply repeat after that
          numDays = x; // 1
        } else {
          numDays = stakedDays; // 2 - repeat number of days
        }
      } else {
        // 4 is a flag to front end that this stake may no longer match its history
        // the reason this must cut off contract controlled days is because
        // we do not have enough bits to store locked day and staked days from
        // previous iterations. the code below either does a shorter or a longer stake
        // depending on the x (bump min) value which helps get around the 0 issue
        // using this feature and not paying attention
        // to your stake could lead to it not being restarted
        // with this constraint, a stake will never be restarted for longer than 2x
        // the original stake - otherwise the stakes could indefinitely elongate
        if (newMethod == FOUR) {
          return (newMethod, ZERO);
        }
        // 3 - start an equally spaced ladder, even if end stake happens late
        uint256 nextLockedDay = today + ONE;
        uint256 lockedDaysDelta = nextLockedDay - lockedDay;
        uint256 stakeDaysConsumption = stakedDays + ONE;
        uint256 stakedDaysModifier = lockedDaysDelta % stakeDaysConsumption;
        numDays = stakedDays - stakedDaysModifier;
        // x is the equivalent to "bump to next stake ladder" if under this value
        if (numDays < x) {
          numDays = stakedDays + numDays + ONE;
        }
        if (numDays != stakedDays) {
          // unless the ladder is being restarted on the end day
          // disallow new stakes until the user updates the setting (reset to 3)
          ++newMethod;
        }
      }
      numDays = numDays > limit ? limit : numDays;
    }
  }
  /**
   * compute a useful value from 2 inputs
   * @param linear holds the linear data to describe how to plot a provied y value
   * @param v2 a secondary magnitude to use - generally the amount of the end stake
   * @param v1 the starting point of v2 used for deltas
   * @notice funds may never be linked to x variable. X should only hold data that we can plug into
   * an expression to tell us where to land on the plot. Result is never less than 0, nor greater than limit
   */
  function _computeMagnitude(
    uint256 limit, uint256 linear,
    uint256 v2, uint256 v1
  ) internal pure returns(uint256 amount) {
    // we can use unchecked here because all minuses (-)
    // are checked before they are run
    unchecked {
      uint256 method = uint8(linear);
      if (method < X_OPTIONS) {
        if (method == ONE) {
          amount = (uint256(uint56(linear >> EIGHT)) << uint256(uint8(linear >> SIXTY_FOUR))); // 1
        } else {
          amount = v2; // 2
        }
      } else {
        Linear memory line = _decodeLinear(linear);
        uint256 delta = _getDelta(line.method, v2, v1);
        if (delta == ZERO) return ZERO;
        // even with uint16 (max: 65535), we can still get down to 0.01% increments
        // with scaling we can go even further (though it is choppier)
        // x has an embedded 1 offset
        int256 x = line.x << (line.xFactor - ONE);
        uint256 y = line.y << line.yFactor;
        int256 b = line.b << line.bFactor;
        int256 amnt = ((x * int256(delta)) / int256(y)) + b;
        amount = amnt < 0 ? ZERO : uint256(amnt);
      }
      amount = amount > limit ? limit : amount;
    }
  }
  function _getDelta(uint256 method, uint256 v2, uint256 v1) internal pure returns(uint256 y) {
    unchecked {
      y = v2;
      if (method == ONE) {
        // v1 only
        y = v1;
      } else if (method == TWO) {
        // yield only
        if (v2 > v1) {
          y = v2 - v1;
        } else {
          y = ZERO;
        }
      }
    }
  }
  struct Linear {
    uint256 method;
    uint256 xFactor;
    int256 x;
    uint256 yFactor;
    uint256 y;
    uint256 bFactor;
    int256 b;
  }
  function encodeLinear(Linear calldata linear) external pure returns(uint256 encoded) {
    return _encodeLinear(linear);
  }
  /**
   * convert an x/y+b linear struct into a number held in under 72 total bits
   * @param linear the struct with all relevant linear data in it
   * @return encoded the encoded numbers describing (x/y)+b
   */
  function _encodeLinear(Linear memory linear) internal pure returns(uint256 encoded) {
    if (linear.method >= X_OPTIONS) revert NotAllowed();
    if (linear.xFactor == ZERO) {
      return uint72(
        uint256(linear.yFactor << SIXTY_FOUR)
        | uint256(uint56(linear.y << EIGHT))
        | uint256(uint8(linear.method))
      );
    }
    // xFactor must be > 0
    unchecked {
      return uint256(
        (uint256(uint16(int16(linear.x)) - uint16(int16(MIN_INT_16))) << FIFTY_SIX)
        | (uint256(uint8(linear.yFactor)) << FOURTY_EIGHT)
        | (uint256(uint16(linear.y)) << THIRTY_TWO)
        | (uint256(uint8(linear.bFactor)) << TWENTY_FOUR)
        | (uint256(uint16(int16(linear.b)) - uint16(int16(MIN_INT_16))) << EIGHT)
        | uint256(uint8((linear.xFactor * X_OPTIONS) + linear.method))
      );
    }
  }
  /**
   * decode an b+(x/y) slope from a number and scale it to your preference
   * @param encodedLinear holds all relevant data for filling out a Linear struct
   * @return linear the full set of parameters to describe a (x/y)+b pattern
   * @notice this limits the bFactor from scaling beyond 2^84, which should be enough for most use cases
   */
  function decodeLinear(uint256 encodedLinear) external pure returns (Linear memory linear) {
    return _decodeLinear({
      encodedLinear: encodedLinear
    });
  }
  function _decodeLinear(uint256 encodedLinear) internal pure returns (Linear memory linear) {
    // only first 72 bits of magnitude are read / relevant for our purposes
    unchecked {
      uint256 method = uint8(encodedLinear);
      linear.xFactor = method / X_OPTIONS;
      linear.method = method % X_OPTIONS;
      // when xFactor is 0, nothing below makes a difference except y
      if (linear.xFactor == ZERO) {
        // y is being used because it is the only uint
        linear.y = (uint256(uint56(encodedLinear >> EIGHT)) << uint8(encodedLinear >> SIXTY_FOUR));
        return linear;
      }
      // numerator
      linear.x = int16(uint16(encodedLinear >> FIFTY_SIX)) + int16(-MIN_INT_16);
      // denominator - uint
      linear.yFactor = uint256(uint8(encodedLinear >> FOURTY_EIGHT)); // udd*(4^sfd)=d
      linear.y = uint16(encodedLinear >> THIRTY_TWO);
      // offset
      linear.bFactor = uint256(uint8(encodedLinear >> TWENTY_FOUR)); // b*(2^sfn)=b
      linear.b = int16(uint16(encodedLinear >> EIGHT)) + int16(-MIN_INT_16);
    }
  }
  /**
   * compute a magnitude given an x and y
   * @param limit a limit that the uint result can not be greater than
   * @param linear the linear data to describe an (x/y)+b relationship
   * @param v2 the second value as input
   * @param v1 the stake to use as an input for the second value
   */
  function computeMagnitude(
    uint256 limit, Linear calldata linear,
    uint256 v2, uint256 v1
  ) external pure returns(uint256 result) {
    // the reason that this condition is necessary is because "method" of a decoded linear struct
    // will range between 0-2 with the first two existing as special cases.
    // after the range 0-2, the linear treatment turns into something actually linear (x/y)+b
    // the flag of xFactor == 0 in combination with method = 0 is used to get around this,
    // or act as a boolean to signal special treatment of 1 and 2
    if (limit == ZERO) {
      return ZERO;
    }
    if (linear.method == ZERO) {
      if (linear.xFactor == ZERO) {
        return ZERO;
      }
    }
    return _computeMagnitude({
      limit: limit,
      linear: _encodeLinear(linear),
      v2: v2,
      v1: v1
    });
  }
  /**
   * compute a day magnitude given an x and y
   * @param limit a limit that the uint result can not be greater than
   * @param method the method to use to compute the result
   * @param x the first value as input
   * @param today the hex day value
   * @param lockedDay the day that the stake was locked
   * @param stakedDays the number of full days that the stake was locked
   */
  function computeDayMagnitude(
    uint256 limit, uint256 method, uint256 x,
    uint256 today,
    uint256 lockedDay,
    uint256 stakedDays
  ) external pure returns(uint256 newMethod, uint256 numDays) {
    if (limit == ZERO || method == ZERO) {
      return (method, ZERO);
    }
    return _computeDayMagnitude({
      limit: limit,
      method: method,
      x: x,
      today: today,
      lockedDay: lockedDay,
      stakedDays: stakedDays
    });
  }
}
