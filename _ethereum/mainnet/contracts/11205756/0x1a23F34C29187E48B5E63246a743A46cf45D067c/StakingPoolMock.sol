// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.7.4;

import "./StakingPool.sol";

contract StakingPoolMock is StakingPool {
  constructor () ERC20('', '') {}

  function mint (address account, uint amount) external {
    _mint(account, amount);
  }

  // override needed for IStakingPool interface
  function distributeRewards (uint amount) override external {
    _distributeRewards(amount);
  }

  function clearRewards (address account) external {
    _clearRewards(account);
  }

  function addToWhitelist (address account) external {
    _addToWhitelist(account);
  }

  function ignoreWhitelist () external {
    _ignoreWhitelist();
  }
}
