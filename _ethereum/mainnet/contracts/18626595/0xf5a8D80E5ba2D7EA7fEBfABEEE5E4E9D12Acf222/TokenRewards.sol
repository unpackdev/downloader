// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./Context.sol";
import "./IStakingPool.sol";

contract TokenRewards is Context {
  using SafeERC20 for IERC20;

  uint256 constant PRECISION = 10 ** 36;

  struct Reward {
    uint256 excluded;
    uint256 realized;
  }

  address public trackingToken;
  address public rewardsToken;
  uint256 public totalShares;
  uint256 public totalStakers;
  mapping(address => uint256) public shares;
  mapping(address => Reward) public rewards;

  uint256 _rewardsSwapSlippage = 10; // 1%
  uint256 _rewardsPerShare;
  uint256 public rewardsDistributed;
  uint256 public rewardsDeposited;
  mapping(uint256 => uint256) public rewardsDepMonthly;

  event AddShares(address indexed wallet, uint256 amount);
  event RemoveShares(address indexed wallet, uint256 amount);
  event ClaimReward(address indexed wallet);
  event DistributeReward(address indexed wallet, uint256 amount);
  event DepositRewards(address indexed wallet, uint256 amount);

  modifier onlyTrackingToken() {
    require(_msgSender() == trackingToken, 'UNAUTHORIZED');
    _;
  }

  constructor(address _trackingToken, address _rewardsToken) {
    trackingToken = _trackingToken;
    rewardsToken = _rewardsToken;
  }

  function setShare(
    address _wallet,
    uint256 _amount,
    bool _sharesRemoving
  ) external onlyTrackingToken {
    if (_sharesRemoving) {
      _removeShares(_wallet, _amount);
      emit RemoveShares(_wallet, _amount);
    } else {
      _addShares(_wallet, _amount);
      emit AddShares(_wallet, _amount);
    }
  }

  function _addShares(address _wallet, uint256 _amount) internal {
    if (shares[_wallet] > 0) {
      _distributeReward(_wallet);
    }
    uint256 sharesBefore = shares[_wallet];
    totalShares += _amount;
    shares[_wallet] += _amount;
    if (sharesBefore == 0 && shares[_wallet] > 0) {
      totalStakers++;
    }
    rewards[_wallet].excluded = _cumulativeRewards(shares[_wallet]);
  }

  function _removeShares(address _wallet, uint256 _amount) internal {
    require(shares[_wallet] > 0 && _amount <= shares[_wallet], 'REMOVE');
    uint256 _unpaid = getUnpaid(_wallet);
    if (_unpaid > 0) {
      _depositRewards(_unpaid);
    }
    totalShares -= _amount;
    shares[_wallet] -= _amount;
    if (shares[_wallet] == 0) {
      totalStakers--;
    }
    rewards[_wallet].excluded = _cumulativeRewards(shares[_wallet]);
  }

  function depositRewards(uint256 _amount) external {
    require(_amount > 0, 'DEPAM');
    uint256 _rewardsBalBefore = IERC20(rewardsToken).balanceOf(address(this));
    IERC20(rewardsToken).safeTransferFrom(_msgSender(), address(this), _amount);
    _depositRewards(
      IERC20(rewardsToken).balanceOf(address(this)) - _rewardsBalBefore
    );
  }

  function _depositRewards(uint256 _depositAmount) internal {
    require(_depositAmount > 0 && totalShares > 0, 'VAL');
    rewardsDeposited += _depositAmount;
    _rewardsPerShare += (PRECISION * _depositAmount) / totalShares;
    emit DepositRewards(_msgSender(), _depositAmount);
  }

  function _distributeReward(address _wallet) internal {
    if (shares[_wallet] == 0) {
      return;
    }
    uint256 _amount = getUnpaid(_wallet);
    rewards[_wallet].realized += _amount;
    rewards[_wallet].excluded = _cumulativeRewards(shares[_wallet]);
    if (_amount > 0) {
      IStakingPool(trackingToken).resetWalletStakedTime(_wallet);
      rewardsDistributed += _amount;
      IERC20(rewardsToken).safeTransfer(_wallet, _amount);
      emit DistributeReward(_wallet, _amount);
    }
  }

  function claimReward() external {
    _distributeReward(_msgSender());
    emit ClaimReward(_msgSender());
  }

  function getUnpaid(address _wallet) public view returns (uint256) {
    if (shares[_wallet] == 0) {
      return 0;
    }
    uint256 earnedRewards = _cumulativeRewards(shares[_wallet]);
    uint256 rewardsExcluded = rewards[_wallet].excluded;
    if (earnedRewards <= rewardsExcluded) {
      return 0;
    }
    return earnedRewards - rewardsExcluded;
  }

  function _cumulativeRewards(uint256 _share) internal view returns (uint256) {
    return (_share * _rewardsPerShare) / PRECISION;
  }
}
