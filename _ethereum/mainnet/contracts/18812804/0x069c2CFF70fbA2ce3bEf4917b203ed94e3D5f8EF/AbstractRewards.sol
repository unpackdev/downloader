// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./IAbstractRewards.sol";
import "./SafeCast.sol";

abstract contract AbstractRewards is IAbstractRewards {
  using SafeCast for uint128;
  using SafeCast for uint256;
  using SafeCast for int256;

  uint128 public constant POINTS_MULTIPLIER = type(uint128).max;

  function(address) view returns (uint256) private immutable getSharesOf;
  function() view returns (uint256) private immutable getTotalShares;

  uint256 public pointsPerShare;
  mapping(address => int256) public pointsCorrection;
  mapping(address => uint256) public withdrawnRewards;

  constructor(
    function(address) view returns (uint256) getSharesOf_,
    function() view returns (uint256) getTotalShares_
  ) {
    getSharesOf = getSharesOf_;
    getTotalShares = getTotalShares_;
  }

  function withdrawableRewardsOf(address _account) public view override returns (uint256) {
    return cumulativeRewardsOf(_account) - withdrawnRewards[_account];
  }

  function withdrawnRewardsOf(address _account) public view override returns (uint256) {
    return withdrawnRewards[_account];
  }

  function cumulativeRewardsOf(address _account) public view override returns (uint256) {
    return ((pointsPerShare * getSharesOf(_account)).toInt256() + pointsCorrection[_account]).toUint256() / POINTS_MULTIPLIER;
  }

  function _distributeAiFi(uint256 _amount) internal {
    uint256 shares = getTotalShares();
    require(shares > 0, "AbstractRewards._distributeAiFi: total share supply is zero");

    if (_amount > 0) {
      pointsPerShare = pointsPerShare + (_amount * POINTS_MULTIPLIER / shares);
      emit RewardsDistributed(msg.sender, _amount);
    }
  }

  function _prepareCollect(address _account) internal returns (uint256) {
    uint256 _withdrawableDividend = withdrawableRewardsOf(_account);
    if (_withdrawableDividend > 0) {
      withdrawnRewards[_account] = withdrawnRewards[_account] + _withdrawableDividend;
      emit RewardsWithdrawn(_account, _withdrawableDividend);
    }
    return _withdrawableDividend;
  }

  function _correctPointsForTransfer(address _from, address _to, uint256 _shares) internal {
    int256 _magCorrection = (pointsPerShare * _shares).toInt256();
    pointsCorrection[_from] = pointsCorrection[_from] + _magCorrection;
    pointsCorrection[_to] = pointsCorrection[_to] - _magCorrection;
  }
}