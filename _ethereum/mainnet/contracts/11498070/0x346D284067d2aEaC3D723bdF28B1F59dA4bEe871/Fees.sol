pragma solidity ^0.6.0;

import "./SafeMath.sol";

library Fees {
  using SafeMath for uint256;

  function getFee(uint256 amount, uint256 tax) internal pure returns (uint256) {
    return amount.mul(tax).div(10000);
  }
}
