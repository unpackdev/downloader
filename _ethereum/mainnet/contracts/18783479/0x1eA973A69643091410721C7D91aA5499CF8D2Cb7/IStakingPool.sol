// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./IERC20.sol";
import "./StakingPool.sol";

interface IStakingPool {
    function cancelUnstaking(uint256 amount) external returns (bool success);
    function claim(uint256 amount) external returns (uint256 claimedAmount, uint256 burnedAmount);
    function claimFees() external returns (uint256 amount);
    function createNewStrategy(
        uint256 perBlockReward_,
        uint256 startBlockNumber_,
        uint256 duration_
    )
        external
        returns (bool success);
    function decreasePool(uint256 amount) external returns (bool success);
    function increasePool(uint256 amount) external returns (bool success);
    function setClaimingFeePercent(uint256 feePercent) external returns (bool success);
    function stake(uint256 amount, bytes32[] calldata proof) external returns (uint256 mintedAmount);
    function stakeForUser(
        address account,
        uint256 amount,
        bytes32[] calldata proof
    )
        external
        returns (uint256 mintedAmount);
    function unstake(uint256 amount) external returns (uint256 unstakedAmount, uint256 burnedAmount);
    function update() external returns (bool success);
    function withdraw() external returns (bool success);
    function setUnstakingTime(uint256 unstakingTime_) external returns (bool success);

    function feePool() external view returns (uint256);

    function lockedRewards() external view returns (uint256);

    function totalStaked() external view returns (uint256);

    function totalUnstaked() external view returns (uint256);

    function stakingToken() external view returns (IERC20);

    function unstakingTime() external view returns (uint256);

    function currentStrategy() external view returns (StakingPool.Strategy memory);

    function nextStrategy() external view returns (StakingPool.Strategy memory);

    function getUnstake(address account) external view returns (StakingPool.Unstake memory result);

    function defaultPrice() external view returns (uint256 mantissa, uint256 base, uint256 exponentiation);

    function getCurrentStrategyUnlockedRewards() external view returns (uint256 unlocked);

    function getUnlockedRewards() external view returns (uint256 unlocked, bool currentStrategyEnded);

    function price() external view returns (uint256 mantissa, uint256 base, uint256 exponentiation);

    function priceStored() external view returns (uint256 mantissa, uint256 base, uint256 exponentiation);

    function calculateUnstake(
        address account,
        uint256 amount
    )
        external
        view
        returns (uint256 unstakedAmount, uint256 burnedAmount);

    event Claimed(
        address indexed account, uint256 requestedAmount, uint256 claimedAmount, uint256 feeAmount, uint256 burnedAmount
    );

    event ClaimingFeePercentUpdated(uint256 feePercent);
    event CurrentStrategyUpdated(uint256 perBlockReward, uint256 startBlockNumber, uint256 endBlockNumber);
    event FeeClaimed(address indexed receiver, uint256 amount);

    event Migrated(
        address indexed account, uint256 omTokenV1StakeAmount, uint256 stakingPoolV1Reward, uint256 stakingPoolV2Reward
    );

    event NextStrategyUpdated(uint256 perBlockReward, uint256 startBlockNumber, uint256 endBlockNumber);
    event UnstakingTimeUpdated(uint256 unstakingTime);
    event NextStrategyRemoved();
    event PoolDecreased(uint256 amount);
    event PoolIncreased(address indexed payer, uint256 amount);
    event PriceUpdated(uint256 mantissa, uint256 base, uint256 exponentiation);
    event RewardsUnlocked(uint256 amount);
    event Staked(address indexed account, address indexed payer, uint256 stakedAmount, uint256 mintedAmount);
    event Unstaked(
        address indexed account,
        uint256 requestedAmount,
        uint256 unstakedAmount,
        uint256 burnedAmount,
        uint256 applicableAt
    );
    event UnstakingCanceled(address indexed account, uint256 amount);
    event Withdrawed(address indexed account, uint256 amount);
}
