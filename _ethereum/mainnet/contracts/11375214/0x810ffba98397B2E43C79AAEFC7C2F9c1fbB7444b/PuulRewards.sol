// SPDX-License-Identifier: Apache-2.0-with-puul-exception
pragma solidity >=0.6.12;
import "./SafeMath.sol";
import "./Address.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./PuulAccessControl.sol";
import "./Console.sol";
import "./IPool.sol";
import "./IFarm.sol";
import "./IFarmRewards.sol";

contract PuulRewards is PuulAccessControl, IPool, IFarmRewards {
  using Address for address;
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  IFarm _farm;
  IERC20[] _rewards;
  mapping (IERC20 => uint256) _rewardsMap;
  mapping (IERC20 => uint256) _rewardTotals;

  modifier onlyFarm() virtual {
    require(msg.sender == address(_farm), '!farm');
    _;
  }

  function _addRewards(address[] memory rewards) internal {
    for (uint256 i = 0; i < rewards.length; i++) {
      _addReward(rewards[i]);
    }
  }

  function setFarm(address farm) onlyAdmin external {
    _farm = IFarm(farm);
    address[] memory rewards = IFarmRewards(address(_farm)).rewards();
    for (uint256 i = 0; i < rewards.length; i++) {
      _addReward(rewards[i]);
    }
  }

  function getFarm() external view returns(address) {
    return address(_farm);
  }

  function addReward(address token) onlyAdmin external virtual {
    _addReward(token);
  }

  function _getRewards() internal view returns(address[] memory result) {
    result = new address[](_rewards.length);
    for (uint256 i = 0; i < _rewards.length; i++) {
      result[i] = address(_rewards[i]);
    }
  }

  function rewards() external view override returns(address[] memory result) {
    return _getRewards();
  }

  function rewardAdded(address token) onlyFarm external override virtual {
    _addReward(token);
  }

  function safeTransferReward(IERC20 reward, address dest, uint256 amount) internal returns(uint256) {
    // in case there is a tiny rounding error
    uint256 remaining = _rewardTotals[reward];
    if (remaining < amount)
      amount = remaining;
    _rewardTotals[reward] = remaining - amount;
    if (amount > 0) {
      uint256 bef = reward.balanceOf(dest);
      reward.safeTransfer(dest, amount);
      uint256 aft = reward.balanceOf(dest);
      amount = aft.sub(bef, '!reward');
    }
    return amount;
  }

  function rewardTotals() onlyHarvester external view returns(uint256[] memory totals) {
    totals = new uint256[](_rewards.length);
    for (uint256 i = 0; i < _rewards.length; i++) {
      totals[i] = _rewardTotals[_rewards[i]];
    }
  }

  function _addReward(address token) internal returns(bool) {
    IERC20 erc = IERC20(token);
    if (_rewardsMap[erc] == 0) {
      _rewards.push(erc);
      _rewardsMap[erc] = _rewards.length;
      return true;
    }
    return false;
  }

  function _tokenInUse(address token) override virtual internal view returns(bool) {
    return _rewardsMap[IERC20(token)] != 0;
  }

}
