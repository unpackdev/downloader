// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.7.4;

import "./ERC20.sol";

import "./IStakingPool.sol";

abstract contract StakingPool is IStakingPool, ERC20 {
  uint private constant REWARD_SCALAR = 1e18;

  // values scaled by REWARD_SCALAR
  uint private _cumulativeRewardPerToken;
  mapping (address => uint) private _rewardsExcluded;
  mapping (address => uint) private _rewardsReserved;

  mapping (address => bool) private _transferWhitelist;
  bool private _skipWhitelist;

  /**
   * @notice get rewards of given account available for withdrawal
   * @param account owner of rewards
   * @return uint quantity of rewards available
   */
  function rewardsOf (address account) public view returns (uint) {
    return (
      balanceOf(account) * _cumulativeRewardPerToken
      + _rewardsReserved[account]
      - _rewardsExcluded[account]
    ) / REWARD_SCALAR;
  }

  /**
   * @notice distribute rewards proportionally to stake holders
   * @param amount quantity of rewards to distribute
   */
  function _distributeRewards (uint amount) internal {
    uint supply = totalSupply();
    require(supply > 0, 'StakingPool: supply must be greater than zero');
    _cumulativeRewardPerToken += amount * REWARD_SCALAR / supply;
  }

  /**
   * @notice remove pending rewards associated with account
   * @param account owner of rewards
   */
  function _clearRewards (address account) internal {
    _rewardsExcluded[account] = balanceOf(account) * _cumulativeRewardPerToken;
    delete _rewardsReserved[account];
  }

  /**
   * @notice add address to transfer whitelist to allow it to execute transfers
   * @param account address to add to whitelist
   */
  function _addToWhitelist (address account) internal {
    _transferWhitelist[account] = true;
  }

  /**
   * @notice disregard transfer whitelist
   */
  function _ignoreWhitelist () internal {
    _skipWhitelist = true;
  }

  /**
   * @notice OpenZeppelin ERC20 hook: prevent manual transfers, maintain reward distribution when tokens are transferred
   * @param from sender
   * @param to recipient
   * @param amount quantity transferred
   */
  function _beforeTokenTransfer (address from, address to, uint amount) virtual override internal {
    super._beforeTokenTransfer(from, to, amount);

    if (from != address(0) && to != address(0)) {
      require(_transferWhitelist[msg.sender] || _skipWhitelist, 'JusDeFi: staked tokens are non-transferrable');
    }

    uint delta = amount * _cumulativeRewardPerToken;

    if (from != address(0)) {
      uint excluded = balanceOf(from) * _cumulativeRewardPerToken;
      _rewardsReserved[from] += excluded - _rewardsExcluded[from];
      _rewardsExcluded[from] = excluded - delta;
    }

    if (to != address(0)) {
      _rewardsExcluded[to] += delta;
    }
  }
}
