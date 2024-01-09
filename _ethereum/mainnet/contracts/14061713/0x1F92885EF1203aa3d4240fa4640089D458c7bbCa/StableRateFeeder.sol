// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

import "./SafeMath.sol";
import "./Math.sol";


/* 
For a given APY (annual percentage yield) this contract calculates aToken/token exchange rate 
at any point in time after the contract deployment.

The formula is: currentValue = startValue * apy^(seconds/secondsPerYear). 
The second multiplier in this formula can be further represented as follows:
apy^(seconds/secondsPerYear) = 
  apy^((1/secondsPerYear)*seconds) = 
  (apy^(1/secondsPerYear))^seconds

Where apy^(1/secondsPerYear) is a constant which represents second to second growth of aToken/token 
exchange rate. This way formula becomes: currentValue = startValue * second_to_second_rate^seconds

Contract's constructor accepts two values: start_value and second_to_second_rate. The tricky part is 
how to calculate power of second_to_second_rate constant.

To do that using only integer ethereum arithmetic we pre-build table with following values
_rate_pows_num[0] = second_to_second_rate
_rate_pows_num[1] = second_to_second_rate^2
_rate_pows_num[2] = second_to_second_rate^4
_rate_pows_num[3] = second_to_second_rate^8
...
_rate_pows_num[31] = second_to_second_rate^32

We then use binary representation of seconds value, e.g. seconds = 13 = 0b1101 which is (1)*2^3 + (1)*2^2 + (0)*2^1 + (1)*2^0

second_to_second_rate^seconds = 
  second_to_second_rate^(1*2^3 + 1*2^2 + 0*2^1 + 1*2^0) =
  second_to_second_rate^(1*2^3) * second_to_second_rate^(1*2^2) * 1 * second_to_second_rate^(1*2^0) =
  second_to_second_rate^8 * second_to_second_rate^4 * second_to_second_rate =
  _rate_pows_num[3] * _rate_pows_num[2] * _rate_pows_num[0]

To use binary representation we use binary shift >> 1 and check the first bit every iteration

Please google for "binary exponention" or "exponention by squaring" for further details, 
e.g. https://cp-algorithms.com/algebra/binary-exp.html
*/

contract StableRateFeeder {
  using Math for uint256;
  using SafeMath for uint256;

  uint256 public start_value;
  uint32 public start_value_decimals;
  uint256 internal _start_value_denom; // 10^start_value_decimals

  uint256[1] internal _rate_pows_num; // rate_pows[i] = _second_to_second_rate^(2^i) * 10^rate_decimals;
  uint256 internal _rate_pows_denom;  // 10^rate_decimals

  uint public start_timestamp;

  //                         start_value_num
  // real start_value = ------------------------
  //                     10^start_value_decimals_
  constructor(uint256 start_value_num, uint32 start_value_decimals_,
              uint256 second_to_second_rate, uint32 rate_decimals) public {
    require(start_value_num != 0, "Start value can't be zero");
    require(start_value_decimals_ > 0 && start_value_decimals_ <= 59,
      "start_value_decimals should be more then 0 and less then 59");
    require(rate_decimals > 0 && rate_decimals <= 38,
      "rate_decimals should be more then 0 and less then 38");

    start_value = start_value_num;
    start_value_decimals = start_value_decimals_;
    _start_value_denom = 10 ** uint256(start_value_decimals);

    _rate_pows_num[0] = second_to_second_rate;
    _rate_pows_denom = 10 ** uint256(rate_decimals);

    start_timestamp = block.timestamp;
  }

  function getRatePow(uint n) public view returns (uint256) {
    uint256 rate_pow = _rate_pows_num[0];
    uint256 denom = _rate_pows_denom;
    for (uint i; i < n; ++i) {
      rate_pow = rate_pow.mul(rate_pow).div(denom);
    }
    return rate_pow;
  }

  // returns value * (second_to_second_rate)^pow_count
  function powerValueBy(uint256 value, uint pow_count) internal view returns (uint256) {
    uint256 rate_pow = _rate_pows_num[0];
    uint256 denom = _rate_pows_denom;
    for (uint i = 0; pow_count != 0; ++i) {
      if (pow_count & 1 != 0) {
        value = value.mul(rate_pow).div(denom);
      }
      rate_pow = rate_pow.mul(rate_pow).div(denom);
      pow_count >>= 1;
    }

    return value;
  }

  function getYearRate() public view returns (uint256) {
    return powerValueBy(1e18, 60*60*24*365);
  }

  function multiplyByRate(uint256 value, uint timestamp) public view returns (uint256) {
    require(timestamp >= start_timestamp, "Can't proceed the past");

    value = value.mul(start_value).div(_start_value_denom);
    if (timestamp > start_timestamp) {
      uint pow_count = timestamp - start_timestamp;
      return powerValueBy(value, pow_count);
    }
    return value;
  }

  function multiplyByCurrentRate(uint256 value) public view returns (uint256) {
    return multiplyByRate(value, block.timestamp);
  }
}
