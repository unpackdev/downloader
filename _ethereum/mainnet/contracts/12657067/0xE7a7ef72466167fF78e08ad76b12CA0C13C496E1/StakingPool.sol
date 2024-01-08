// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

abstract contract StakingPool {
  uint private constant SCALE = 1e18;
  uint private _rewardPerToken;
  mapping (address => uint) private _rewardsAccounted;
  mapping (address => uint) private _rewardsSkipped;

  // credits for tax distribution
  mapping (address => uint) private _taxCredits;
  uint private _taxCreditsTotal;

  function taxCreditsOf (
    address account
  ) public view returns (uint) {
    return _taxCredits[account];
  }

  function taxRewardsOf (
    address account
  ) public view returns (uint) {
    return (_taxCredits[account] * _rewardPerToken + _rewardsAccounted[account] - _rewardsSkipped[account]) / SCALE;
  }

  function _distributeTax (
    uint amount
  ) internal {
    _rewardPerToken += amount * SCALE / _taxCreditsTotal;
  }

  function _mintTaxCredit (
    address account,
    uint amount
  ) internal {
    uint skipped = taxCreditsOf(account) * _rewardPerToken;
    _rewardsAccounted[account] += skipped - _rewardsSkipped[account];
    _rewardsSkipped[account] = skipped - amount * _rewardPerToken;

    _taxCredits[account] += amount;
    _taxCreditsTotal += amount;
  }

  function _burnTaxCredit (
    address account
  ) internal {
    _taxCreditsTotal -= _taxCredits[account];
    delete _taxCredits[account];
  }
}
