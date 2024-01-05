// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

import "./SafeMath.sol";
import "./Ownable.sol";

contract FundraiserManager is Ownable {
  using SafeMath for uint256;

  event ExpirationTimeChanged(uint256 expirationTime);
  event FeeChanged(uint256 fee);

  uint256 public expirationTime;
  uint256 public fee; // USDC has 6 decimal places

  constructor(uint256 _expirationTime, uint256 _fee) {
    expirationTime = _expirationTime;
    fee = _fee;
  }

  function setExpirationTime(uint256 _time) external onlyOwner returns (uint256) {
    expirationTime = _time;
    emit ExpirationTimeChanged(expirationTime);
    return expirationTime;
  }

  function setFee(uint256 _fee) external onlyOwner returns (uint256) {
    fee = _fee;
    emit FeeChanged(fee);
    return fee;
  }
}
