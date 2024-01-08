// SPDX-License-Identifier: MIT
// Forked from Merit Circle
pragma solidity 0.8.7;

import "./LiquidityMiningManager.sol";
import "./FancyStakingPool.sol";
import "./FancyEscrowPool.sol";

/// @dev reader contract to easily fetch all relevant info for an account
contract View {
    struct Data {
        uint256 pendingRewards;
        Pool[] pools;
        EscrowPool escrowPool;
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

    struct EscrowPool {
        address poolAddress;
        uint256 totalPoolShares;
        uint256 accountTotalDeposit;
        uint256 accountPoolShares;
        FancyEscrowPool.Deposit[] deposits;
    }

    LiquidityMiningManager public immutable liquidityMiningManager;
    FancyEscrowPool public immutable escrowPool;

    constructor(address _liquidityMiningManager, address _escrowPool) {
        liquidityMiningManager = LiquidityMiningManager(_liquidityMiningManager);
        escrowPool = FancyEscrowPool(_escrowPool);
    }

    function fetchData(address _account) external view returns (Data memory result) {
//        uint256 rewardPerSecond = liquidityMiningManager.rewardPerSecond();
//        uint256 lastDistribution = liquidityMiningManager.lastDistribution();
//        uint256 pendingRewards = rewardPerSecond * (block.timestamp - lastDistribution);

        result.totalWeight = liquidityMiningManager.totalWeight();

        LiquidityMiningManager.Pool[] memory pools = liquidityMiningManager.getPools();

        result.pools = new Pool[](pools.length);

        for (uint256 i; i < pools.length; i++) {
            FancyStakingPool poolContract = FancyStakingPool(address(pools[i].poolContract));

            result.pools[i] = Pool({
                poolAddress: address(pools[i].poolContract),
                totalPoolShares: poolContract.totalSupply(),
                depositToken: address(poolContract.depositToken()),
                accountPendingRewards: poolContract.withdrawableRewardsOf(_account),
                accountClaimedRewards: poolContract.withdrawnRewardsOf(_account),
                accountTotalDeposit: poolContract.getTotalDeposit(_account),
                accountPoolShares: poolContract.balanceOf(_account),
                weight: pools[i].weight,
                deposits: new Deposit[](poolContract.getDepositsOfLength(_account))
            });

            FancyStakingPool.Deposit[] memory deposits = poolContract.getDepositsOf(_account);

            for (uint256 j; j < result.pools[i].deposits.length; j++) {
                FancyStakingPool.Deposit memory deposit = deposits[j];
                result.pools[i].deposits[j] = Deposit({
                    amount: deposit.amount,
                    start: deposit.start,
                    end: deposit.end,
                    multiplier: poolContract.getMultiplier(deposit.end - deposit.start)
                });
            }
        }

        result.escrowPool = EscrowPool({
            poolAddress: address(escrowPool),
            totalPoolShares: escrowPool.totalSupply(),
            accountTotalDeposit: escrowPool.getTotalDeposit(_account),
            accountPoolShares: escrowPool.balanceOf(_account),
            deposits: new FancyEscrowPool.Deposit[](escrowPool.getDepositsOfLength(_account))
        });

        FancyEscrowPool.Deposit[] memory deposits = escrowPool.getDepositsOf(_account);

        for (uint256 j; j < result.escrowPool.deposits.length; j++) {
            FancyEscrowPool.Deposit memory deposit = deposits[j];
            result.escrowPool.deposits[j] = FancyEscrowPool.Deposit({
                amount: deposit.amount,
                start: deposit.start,
                end: deposit.end
            });
        }
    }
}
