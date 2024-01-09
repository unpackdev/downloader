// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./StakingPoolManager.sol";
import "./StakingPool.sol";

/// @dev reader contract to easily fetch all relevant info for an account
contract View {
  struct Data {
    uint256 pendingRewards;
    Pool[] pools;
    Pool escrowPool;
    uint256 totalWeight;
  }

  struct Deposit {
    uint256 amount;
    uint64 start;
    uint64 end;
    uint256 multiplier;
  }

  struct Pool {
    address poolAddress;
    uint256 totalPoolShares;
    address depositToken;
    uint256 accountPendingRewards;
    uint256 accountClaimedRewards;
    uint256 accountTotalDeposit;
    uint256 accountPoolShares;
    uint256 weight;
    Deposit[] deposits;
  }

  StakingPoolManager public immutable stakingPoolManager;
  StakingPool public immutable escrowPool;

  constructor(address _stakingPoolManager, address _escrowPool) {
    stakingPoolManager = StakingPoolManager(_stakingPoolManager);
    escrowPool = StakingPool(_escrowPool);
  }

  function fetchData(address _account) external view returns (Data memory result) {
    uint256 rewardPerBlock = stakingPoolManager.rewardPerBlock();
    uint256 rewardEndBlock = stakingPoolManager.rewardEndBlock();
    uint256 lastRewardBlock = stakingPoolManager.lastRewardBlock();
    uint256 pendingRewards = rewardPerBlock *
      stakingPoolManager.getMultiplier(lastRewardBlock, block.number, rewardEndBlock);

    result.pendingRewards = pendingRewards;
    result.totalWeight = stakingPoolManager.totalWeight();

    StakingPoolManager.Pool[] memory pools = stakingPoolManager.getPools();

    result.pools = new Pool[](pools.length);

    for (uint256 i = 0; i < pools.length; i++) {
      StakingPool poolContract = StakingPool(address(pools[i].poolContract));
      uint256 depositsOfLength = poolContract.getDepositsOfLength(_account);

      result.pools[i] = Pool({
        poolAddress: address(pools[i].poolContract),
        totalPoolShares: poolContract.totalSupply(),
        depositToken: address(poolContract.depositToken()),
        accountPendingRewards: poolContract.withdrawableRewardsOf(_account),
        accountClaimedRewards: poolContract.withdrawnRewardsOf(_account),
        accountTotalDeposit: poolContract.totalDepositOf(_account),
        accountPoolShares: poolContract.balanceOf(_account),
        weight: pools[i].weight,
        deposits: new Deposit[](depositsOfLength)
      });

      StakingPool.Deposit[] memory poolDeposits = poolContract.getDepositsOf(_account, 0, depositsOfLength);

      for (uint256 j = 0; j < result.pools[i].deposits.length; j++) {
        StakingPool.Deposit memory deposit = poolDeposits[j];
        result.pools[i].deposits[j] = Deposit({
          amount: deposit.amount,
          start: deposit.start,
          end: deposit.end,
          multiplier: poolContract.getMultiplier(deposit.end - deposit.start)
        });
      }
    }

    result.escrowPool = Pool({
      poolAddress: address(escrowPool),
      totalPoolShares: escrowPool.totalSupply(),
      depositToken: address(escrowPool.depositToken()),
      accountPendingRewards: escrowPool.withdrawableRewardsOf(_account),
      accountClaimedRewards: escrowPool.withdrawnRewardsOf(_account),
      accountTotalDeposit: escrowPool.totalDepositOf(_account),
      accountPoolShares: escrowPool.balanceOf(_account),
      weight: 0,
      deposits: new Deposit[](escrowPool.getDepositsOfLength(_account))
    });

    StakingPool.Deposit[] memory escrowDeposits = escrowPool.getDepositsOf(
      _account,
      0,
      escrowPool.getDepositsOfLength(_account)
    );

    for (uint256 j = 0; j < result.escrowPool.deposits.length; j++) {
      StakingPool.Deposit memory deposit = escrowDeposits[j];
      result.escrowPool.deposits[j] = Deposit({
        amount: deposit.amount,
        start: deposit.start,
        end: deposit.end,
        multiplier: escrowPool.getMultiplier(deposit.end - deposit.start)
      });
    }
  }
}
