// SPDX-License-Identifier: GPL-3.0

pragma solidity =0.6.12;

library UniformRandomNumber {
  function uniform(uint256 _entropy, uint256 _upperBound) internal pure returns (uint256) {
    require(_upperBound > 0, "UNIFORMRANDOMNUMBER: MIN_BOUND");
    uint256 min = -_upperBound % _upperBound;
    uint256 random = _entropy;
    while (true) {
      if (random >= min) {
        break;
      }
      random = uint256(keccak256(abi.encodePacked(random)));
    }
    return random % _upperBound;
  }
}