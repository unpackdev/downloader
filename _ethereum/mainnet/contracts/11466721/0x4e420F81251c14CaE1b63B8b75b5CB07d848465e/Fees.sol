// SPDX-License-Identifier: Apache-2.0-with-puul-exception
pragma solidity >=0.6.12;

import "./SafeMath.sol";
import "./ReentrancyGuard.sol";
import "./PuulAccessControl.sol";
import "./Console.sol";

contract Fees is PuulAccessControl, ReentrancyGuard {
  using SafeMath for uint256;

  address _currency;
  address _reward;
  uint256 _rewardFee;
  address _withdrawal;
  uint256 _withdrawalFee;
  address _helper;

  uint256 constant FEE_BASE = 10000;
  
  constructor (address helper, address withdrawal, uint256 withdrawalFee, address reward, uint256 rewardFee) public {
    _helper = helper;
    _reward = reward;
    _rewardFee = rewardFee;
    _withdrawal = withdrawal;
    _withdrawalFee = withdrawalFee;

    _setupRole(ROLE_ADMIN, msg.sender);
  }

  function setupRoles(address admin) onlyDefaultAdmin external {
    _setupAdmin(admin);
    _setupDefaultAdmin(admin);
  }

  function currency() external view returns (address) {
    return _currency;
  }

  function helper() external view returns (address) {
    return _helper;
  }

  function reward() external view returns (address) {
    return _reward;
  }

  function withdrawal() external view returns (address) {
    return _withdrawal;
  }

  function setHelper(address help) onlyAdmin external {
    _helper = help;
  }

  function setCurrency(address curr) onlyAdmin external {
    _currency = curr;
  }

  function setRewardFee(address to, uint256 fee) onlyAdmin external {
    _reward = to;
    _rewardFee = fee;
  }

  function setWithdrawalFee(address to, uint256 fee) onlyAdmin external {
    _withdrawal = to;
    _withdrawalFee = fee;
  }

  function _calcFee(uint256 amount, uint256 fee) internal pure returns (uint256) {
    return amount.mul(fee).div(FEE_BASE);
  }

  function _calcWithdrawalFee(uint256 amount) internal view returns (uint256) {
    return _withdrawalFee == 0 || _withdrawal == address(0) ? 0 : _calcFee(amount, _withdrawalFee);
  }

  function _calcRewardFee(uint256 amount) internal view returns (uint256) {
    return _rewardFee == 0 || _reward == address(0) ? 0 : _calcFee(amount, _rewardFee);
  }

  function getRewardFee() external view returns (uint256) {
    return _rewardFee;
  }

  function rewardFee(uint256 amount) external view returns (uint256) {
    return _calcRewardFee(amount);
  }

  function getWithdrawalFee() external view returns (uint256) {
    return _withdrawalFee;
  }

  function withdrawalFee(uint256 amount) external view returns (uint256) {
    return _calcWithdrawalFee(amount);
  }

}
