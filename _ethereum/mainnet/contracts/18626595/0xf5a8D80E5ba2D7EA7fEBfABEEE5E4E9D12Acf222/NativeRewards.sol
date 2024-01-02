// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "./Context.sol";
import "./IStakingPool.sol";

contract NativeRewards is Context {
  uint256 constant PRECISION = 10 ** 36;
  address public controllerToken;
  uint256 public totalUsers;
  uint256 public totalShares;
  struct Reward {
    uint256 excluded;
    uint256 realized;
  }
  mapping(address => uint256) public shares;
  mapping(address => Reward) public rewards;

  uint256 _rewardsPerShare;
  uint256 public totalDistributed;
  uint256 public totalDeposited;

  event AddShares(address indexed user, uint256 amount);
  event RemoveShares(address indexed user, uint256 amount);
  event ClaimReward(address user);
  event DistributeReward(address indexed user, uint256 amount);
  event DepositRewards(address indexed user, uint256 amountTokens);

  modifier onlyControllerToken() {
    require(_msgSender() == controllerToken, 'TOKEN');
    _;
  }

  constructor(address _controllerToken) {
    controllerToken = _controllerToken;
  }

  function setShare(
    address _wallet,
    uint256 _balUpdate,
    bool _removing
  ) public onlyControllerToken {
    _setShare(_wallet, _balUpdate, _removing);
  }

  function _setShare(
    address _wallet,
    uint256 _balUpdate,
    bool _removing
  ) internal {
    if (_removing) {
      _removeShares(_wallet, _balUpdate);
      emit RemoveShares(_wallet, _balUpdate);
    } else {
      _addShares(_wallet, _balUpdate);
      emit AddShares(_wallet, _balUpdate);
    }
  }

  function _addShares(address _wallet, uint256 _amount) private {
    if (shares[_wallet] > 0) {
      _distributeReward(_wallet);
    }
    uint256 sharesBefore = shares[_wallet];
    totalShares += _amount;
    shares[_wallet] += _amount;
    if (sharesBefore == 0 && shares[_wallet] > 0) {
      totalUsers++;
    }
    rewards[_wallet].excluded = _cumulativeRewards(shares[_wallet]);
  }

  function _removeShares(address _wallet, uint256 _amount) private {
    require(shares[_wallet] > 0 && _amount <= shares[_wallet], 'REMOVE');
    uint256 _unpaid = getUnpaid(_wallet);
    if (_unpaid > 0) {
      _depositRewards(_unpaid);
    }
    totalShares -= _amount;
    shares[_wallet] -= _amount;
    if (shares[_wallet] == 0) {
      totalUsers--;
    }
    rewards[_wallet].excluded = _cumulativeRewards(shares[_wallet]);
  }

  function depositRewards() external payable {
    _depositRewards(msg.value);
  }

  function _depositRewards(uint256 _amount) internal {
    require(_amount > 0, 'DEPOSIT0');
    require(totalShares > 0, 'DEPOSIT1');
    totalDeposited += _amount;
    _rewardsPerShare += (PRECISION * _amount) / totalShares;
    emit DepositRewards(_msgSender(), _amount);
  }

  function _distributeReward(address _wallet) internal {
    if (shares[_wallet] == 0) {
      return;
    }
    uint256 amount = getUnpaid(_wallet);
    rewards[_wallet].realized += amount;
    rewards[_wallet].excluded = _cumulativeRewards(shares[_wallet]);
    if (amount > 0) {
      IStakingPool(controllerToken).resetWalletStakedTime(_wallet);
      totalDistributed += amount;
      uint256 _balBefore = address(this).balance;
      (bool success, ) = payable(_wallet).call{ value: amount }('');
      require(success, 'DIST0');
      require(address(this).balance >= _balBefore - amount, 'DIST1');
      emit DistributeReward(_wallet, amount);
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

  receive() external payable {
    _depositRewards(msg.value);
  }
}
