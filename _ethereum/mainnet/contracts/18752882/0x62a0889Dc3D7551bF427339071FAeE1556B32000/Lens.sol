// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./IRegistry.sol";
import "./IPool.sol";
import "./Pool.sol";
import "./IERC20Metadata.sol";
import "./Error.sol";

contract Lens {
    /// @notice Registry contract these queries will utilize
    IRegistry public immutable registry;

    struct PoolData {
        /// @notice Symbol of the staking/reward token for the pool
        string tokenSymbol;
        /// @notice Decimals of the staking/reward token for the pool
        uint256 tokenDecimals;
        /// @notice Name of the staking/reward token for the pool
        string tokenName;
        /// @notice Address of the staking/reward token for the pool
        address tokenAddress;
        /// @notice Status of the pool
        IPool.Status poolStatus;
        /// @notice Chain the pool exists on
        uint256 chainId;
        /// @notice Reward per token for the current time. See rewardPerToken() on the pool for more info.
        uint256 rewardPerToken;
        /// @notice Current amount of tokens staked in the pool
        uint256 totalSupply;
        /// @notice Total amount of tokens staked in the pool
        uint256 totalSupplyLocked;
        /// @notice Overall capacity of the pool
        uint256 capacity;
        /// @notice Address of the pool
        address poolAddress;
        /// @notice Max amount of tokens that can be staked per wallet
        uint256 maxStakePerAddress;
        /// @notice Number of stakers in the pool
        uint256 seedParticipants;
        /// @notice If provided when querying, the wallets current staked balance
        uint256 queriedUserBalance;
        /// @notice If provided when querying, the total tokens they had locked
        uint256 queriedUserBalanceLocked;
        /// @notice The amount of tokens currently earned by the queried user
        uint256 queriedUserEarned;
        /// @notice The reward paid per token to the queried user
        uint256 queriedUserRewardPerTokenPaid;
        /// @notice The timestamp when the seeding period starts.
        uint256 seedingStart;
        /// @notice The duration of the seeding period.
        uint256 seedingPeriod;
        /// @notice The timestamp when the locked period starts.
        uint256 lockedStart;
        /// @notice The duration of the lock period, which is also the duration of rewards.
        uint256 lockPeriod;
        /// @notice The timestamp when the rewards period ends.
        uint256 periodFinish;
        /// @notice The wallet that deployed the pool
        address creator;
        /// @notice The amount of rewards being distributed
        uint256 rewardAmount;
        /// @notice The fee amount take by the protocol
        uint256 feeAmount;
        /// @notice The amount of protocol fee in basis points (bps) to be paid to the treasury. 1 bps is 0.01%
        uint256 protocolFeeBps;
        /// @notice The amount of reward tokens distributed per second during the `locked` period.
        uint256 rewardPerTokenStored;
    }

    constructor(IRegistry _registry) {
        if (address(_registry) == address(0)) revert Error.ZeroAddress();

        registry = _registry;
    }

    /**
     * @notice Get data for all pools in the registry of the specified type
     * @param _pending True to get pools that are in the pending state
     * @return poolData Data for pools
     */
    function getPoolData(bool _pending) external view returns (PoolData[] memory poolData) {
        poolData = getPoolData(_pending, address(0));
    }

    /**
     * @notice Get data for all pools in the registry of the specified type
     * @param _pending True to get pools that are in the pending state
     * @param _user Wallet to include data for the pool results
     * @return poolData Data for pools
     */
    function getPoolData(bool _pending, address _user) public view returns (PoolData[] memory poolData) {
        uint256 pools = registry.getPoolCount(_pending);
        poolData = new PoolData[](pools);
        for (uint256 i = 0; i < pools; ++i) {
            poolData[i] = _getPoolData(registry.getPoolAt(i, _pending), _user);
        }
    }

    /**
     * @notice Get data for a pool
     * @param _poolAddress Address of the pool to get data for
     * @param _user Wallet to include data for the pool results
     * @return poolData Data for the pool
     */
    function _getPoolData(address _poolAddress, address _user) private view returns (PoolData memory poolData) {
        Pool pool = Pool(_poolAddress);
        (uint256 start, uint256 period, uint256 lStart, uint256 lPeriod, uint256 finish) = pool.stakingSchedule();
        IERC20Metadata token = IERC20Metadata(address(pool.token()));

        uint256 queriedUserBalance = 0;
        uint256 queriedUserBalanceLocked = 0;
        uint256 queriedUserEarned = 0;
        uint256 queriedUserRewardPerTokenPaid = 0;

        if (_user != address(0)) {
            queriedUserBalance = pool.balances(_user);
            queriedUserBalanceLocked = pool.balancesLocked(_user);
            queriedUserEarned = pool.earned(_user);
            queriedUserRewardPerTokenPaid = pool.userRewardPerTokenPaid(_user);
        }

        poolData = PoolData({
            tokenSymbol: token.symbol(),
            tokenDecimals: token.decimals(),
            tokenName: token.name(),
            tokenAddress: address(token),
            poolStatus: pool.status(),
            chainId: block.chainid,
            rewardPerToken: pool.rewardPerToken(),
            totalSupply: pool.totalSupply(),
            totalSupplyLocked: pool.totalSupplyLocked(),
            capacity: pool.maxStakePerPool(),
            poolAddress: _poolAddress,
            maxStakePerAddress: pool.maxStakePerAddress(),
            seedParticipants: pool.stakersCount(),
            queriedUserBalance: queriedUserBalance,
            queriedUserBalanceLocked: queriedUserBalanceLocked,
            queriedUserEarned: queriedUserEarned,
            queriedUserRewardPerTokenPaid: queriedUserRewardPerTokenPaid,
            seedingStart: start,
            seedingPeriod: period,
            lockedStart: lStart,
            lockPeriod: lPeriod,
            periodFinish: finish,
            creator: pool.creator(),
            rewardAmount: pool.rewardAmount(),
            feeAmount: pool.feeAmount(),
            protocolFeeBps: pool.protocolFeeBps(),
            rewardPerTokenStored: pool.rewardPerTokenStored()
        });
    }
}
