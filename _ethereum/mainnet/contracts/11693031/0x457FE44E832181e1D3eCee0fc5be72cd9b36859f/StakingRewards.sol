// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./AccessControl.sol";
import "./Math.sol";
import "./SafeMath.sol";
import "./SafeERC20.sol";

import "./ITokenGovernance.sol";
import "./ContractRegistryClient.sol";
import "./Utils.sol";
import "./Time.sol";
import "./ICheckpointStore.sol";
import "./ILiquidityProtection.sol";
import "./ILiquidityProtectionEventsSubscriber.sol";

import "./IStakingRewardsStore.sol";

/**
 * @dev This contract manages the distribution of the staking rewards
 */
contract StakingRewards is ILiquidityProtectionEventsSubscriber, AccessControl, Time, Utils, ContractRegistryClient {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // the role is used to globally govern the contract and its governing roles.
    bytes32 public constant ROLE_SUPERVISOR = keccak256("ROLE_SUPERVISOR");

    // the roles is used to restrict who is allowed to publish liquidity protection events.
    bytes32 public constant ROLE_PUBLISHER = keccak256("ROLE_PUBLISHER");

    uint32 private constant PPM_RESOLUTION = 1000000;

    // the weekly 25% increase of the rewards multiplier (in units of PPM).
    uint32 private constant MULTIPLIER_INCREMENT = PPM_RESOLUTION / 4;

    // the maximum weekly 200% rewards multiplier (in units of PPM).
    uint32 private constant MAX_MULTIPLIER = PPM_RESOLUTION + MULTIPLIER_INCREMENT * 4;

    // since we will be dividing by the total amount of protected tokens in units of wei, we can encounter cases
    // where the total amount in the denominator is higher than the product of the rewards rate and staking duration. In
    // order to avoid this imprecision, we will amplify the reward rate by the units amount.
    uint256 private constant REWARD_RATE_FACTOR = 1e18;

    uint256 private constant MAX_UINT256 = uint256(-1);

    // the staking rewards settings.
    IStakingRewardsStore private immutable _store;

    // the permissioned wrapper around the network token which should allow this contract to mint staking rewards.
    ITokenGovernance private immutable _networkTokenGovernance;

    // the address of the network token.
    IERC20 private immutable _networkToken;

    // the checkpoint store recording last protected position removal times.
    ICheckpointStore private immutable _lastRemoveTimes;

    /**
     * @dev triggered when pending rewards are being claimed
     *
     * @param provider the owner of the liquidity
     * @param amount the total rewards amount
     */
    event RewardsClaimed(address indexed provider, uint256 amount);

    /**
     * @dev triggered when pending rewards are being staked in a pool
     *
     * @param provider the owner of the liquidity
     * @param poolToken the pool token representing the rewards pool
     * @param amount the reward amount
     * @param newId the ID of the new position
     */
    event RewardsStaked(address indexed provider, IDSToken indexed poolToken, uint256 amount, uint256 indexed newId);

    /**
     * @dev initializes a new StakingRewards contract
     *
     * @param store the staking rewards store
     * @param networkTokenGovernance the permissioned wrapper around the network token
     * @param lastRemoveTimes the checkpoint store recording last protected position removal times
     * @param registry address of a contract registry contract
     */
    constructor(
        IStakingRewardsStore store,
        ITokenGovernance networkTokenGovernance,
        ICheckpointStore lastRemoveTimes,
        IContractRegistry registry
    )
        public
        validAddress(address(store))
        validAddress(address(networkTokenGovernance))
        validAddress(address(lastRemoveTimes))
        ContractRegistryClient(registry)
    {
        _store = store;
        _networkTokenGovernance = networkTokenGovernance;
        _networkToken = networkTokenGovernance.token();
        _lastRemoveTimes = lastRemoveTimes;

        // set up administrative roles.
        _setRoleAdmin(ROLE_SUPERVISOR, ROLE_SUPERVISOR);
        _setRoleAdmin(ROLE_PUBLISHER, ROLE_SUPERVISOR);

        // allow the deployer to initially govern the contract.
        _setupRole(ROLE_SUPERVISOR, _msgSender());
    }

    modifier onlyPublisher() {
        _onlyPublisher();
        _;
    }

    function _onlyPublisher() internal view {
        require(hasRole(ROLE_PUBLISHER, msg.sender), "ERR_ACCESS_DENIED");
    }

    /**
     * @dev liquidity provision notification callback. The callback should be called *after* the liquidity is added in
     * the LP contract.
     *
     * @param provider the owner of the liquidity
     * @param poolAnchor the pool token representing the rewards pool
     * @param reserveToken the reserve token of the added liquidity
     */
    function onAddingLiquidity(
        address provider,
        IConverterAnchor poolAnchor,
        IERC20Token reserveToken,
        uint256, /* poolAmount */
        uint256 /* reserveAmount */
    ) external override onlyPublisher validExternalAddress(provider) {
        if (!_store.isReserveParticipating(IDSToken(address(poolAnchor)), reserveToken)) {
            return;
        }

        updateRewards(provider, IDSToken(address(poolAnchor)), reserveToken, liquidityProtectionStats());
    }

    /**
     * @dev liquidity removal callback. The callback must be called *before* the liquidity is removed in the LP
     * contract
     *
     * @param provider the owner of the liquidity
     * @param poolAnchor the pool token representing the rewards pool
     * @param reserveToken the reserve token of the removed liquidity
     */
    function onRemovingLiquidity(
        uint256, /* id */
        address provider,
        IConverterAnchor poolAnchor,
        IERC20Token reserveToken,
        uint256, /* poolAmount */
        uint256 /* reserveAmount */
    ) external override onlyPublisher validExternalAddress(provider) {
        if (!_store.isReserveParticipating(IDSToken(address(poolAnchor)), reserveToken)) {
            return;
        }

        ILiquidityProtectionStats lpStats = liquidityProtectionStats();

        // make sure that all pending rewards are properly stored for future claims, with retroactive rewards
        // multipliers.
        storeRewards(provider, lpStats.providerPools(provider), lpStats);
    }

    /**
     * @dev returns the staking rewards store
     *
     * @return the staking rewards store
     */
    function store() external view returns (IStakingRewardsStore) {
        return _store;
    }

    /**
     * @dev returns the network token governance
     *
     * @return the network token governance
     */
    function networkTokenGovernance() external view returns (ITokenGovernance) {
        return _networkTokenGovernance;
    }

    /**
     * @dev returns the last remove times
     *
     * @return the last remove times
     */
    function lastRemoveTimes() external view returns (ICheckpointStore) {
        return _lastRemoveTimes;
    }

    /**
     * @dev returns specific provider's pending rewards for all participating pools
     *
     * @param provider the owner of the liquidity
     *
     * @return all pending rewards
     */
    function pendingRewards(address provider) external view returns (uint256) {
        return pendingRewards(provider, liquidityProtectionStats());
    }

    /**
     * @dev returns specific provider's pending rewards for a specific participating pool/reserve
     *
     * @param provider the owner of the liquidity
     * @param poolToken the pool token representing the new rewards pool
     * @param reserveToken the reserve token representing the liquidity in the pool
     *
     * @return all pending rewards
     */
    function pendingReserveRewards(
        address provider,
        IDSToken poolToken,
        IERC20Token reserveToken
    ) external view returns (uint256) {
        PoolProgram memory program = poolProgram(poolToken);

        return
            pendingRewards(provider, poolToken, reserveToken, program, liquidityProtectionStats());
    }

    /**
     * @dev returns specific provider's pending rewards for all participating pools
     *
     * @param provider the owner of the liquidity
     * @param lpStats liquidity protection statistics store
     *
     * @return all pending rewards
     */
    function pendingRewards(
        address provider,
        ILiquidityProtectionStats lpStats
    ) private view returns (uint256) {
        return pendingRewards(provider, lpStats.providerPools(provider), lpStats);
    }

    /**
     * @dev returns specific provider's pending rewards for a specific list of participating pools
     *
     * @param provider the owner of the liquidity
     * @param poolTokens the list of participating pools to query
     * @param lpStats liquidity protection statistics store
     *
     * @return all pending rewards
     */
    function pendingRewards(
        address provider,
        IDSToken[] memory poolTokens,
        ILiquidityProtectionStats lpStats
    ) private view returns (uint256) {
        uint256 reward = 0;

        uint256 length = poolTokens.length;
        for (uint256 i = 0; i < length; ++i) {
            uint256 poolReward = pendingRewards(provider, poolTokens[i], lpStats);
            reward = reward.add(poolReward);
        }

        return reward;
    }

    /**
     * @dev returns specific provider's pending rewards for a specific pool
     *
     * @param provider the owner of the liquidity
     * @param poolToken the pool to query
     * @param lpStats liquidity protection statistics store
     *
     * @return reward all pending rewards
     */
    function pendingRewards(
        address provider,
        IDSToken poolToken,
        ILiquidityProtectionStats lpStats
    ) private view returns (uint256) {
        uint256 reward = 0;
        PoolProgram memory program = poolProgram(poolToken);

        for (uint256 i = 0; i < program.reserveTokens.length; ++i) {
            uint256 reserveReward =
                pendingRewards(provider, poolToken, program.reserveTokens[i], program, lpStats);
            reward = reward.add(reserveReward);
        }

        return reward;
    }

    /**
     * @dev returns specific provider's pending rewards for a specific pool/reserve
     *
     * @param provider the owner of the liquidity
     * @param poolToken the pool to query
     * @param reserveToken the reserve token representing the liquidity in the pool
     * @param program the pool program info
     * @param lpStats liquidity protection statistics store
     *
     * @return reward all pending rewards
     */

    function pendingRewards(
        address provider,
        IDSToken poolToken,
        IERC20Token reserveToken,
        PoolProgram memory program,
        ILiquidityProtectionStats lpStats
    ) private view returns (uint256) {
        // calculate the new reward rate per-token
        PoolRewards memory poolRewardsData = poolRewards(poolToken, reserveToken);

        // rewardPerToken must be calculated with the previous value of lastUpdateTime.
        poolRewardsData.rewardPerToken = rewardPerToken(poolToken, reserveToken, poolRewardsData, program, lpStats);
        poolRewardsData.lastUpdateTime = Math.min(time(), program.endTime);

        // update provider's rewards with the newly claimable base rewards and the new reward rate per-token.
        ProviderRewards memory providerRewards = providerRewards(provider, poolToken, reserveToken);

        // if this is the first liquidity provision - set the effective staking time to the current time.
        if (
            providerRewards.effectiveStakingTime == 0 &&
            lpStats.totalProviderAmount(provider, poolToken, reserveToken) == 0
        ) {
            providerRewards.effectiveStakingTime = time();
        }

        // pendingBaseRewards must be calculated with the previous value of providerRewards.rewardPerToken.
        providerRewards.pendingBaseRewards = providerRewards.pendingBaseRewards.add(
            baseRewards(provider, poolToken, reserveToken, poolRewardsData, providerRewards, program, lpStats)
        );
        providerRewards.rewardPerToken = poolRewardsData.rewardPerToken;

        // get full rewards and the respective rewards multiplier.
        (uint256 fullReward,) =
            fullRewards(provider, poolToken, reserveToken, poolRewardsData, providerRewards, program, lpStats);

        return fullReward;
    }

    /**
     * @dev claims specific provider's pending rewards for all participating pools
     *
     * @param provider the owner of the liquidity
     * @param maxAmount an optional bound on the rewards to claim (when partial claiming is required)
     * @param lpStats liquidity protection statistics store
     *
     * @return all pending rewards
     */
    function claimPendingRewards(
        address provider,
        uint256 maxAmount,
        ILiquidityProtectionStats lpStats
    ) private returns (uint256) {
        return claimPendingRewards(provider, lpStats.providerPools(provider), maxAmount, lpStats);
    }

    /**
     * @dev claims specific provider's pending rewards for a specific list of participating pools
     *
     * @param provider the owner of the liquidity
     * @param poolTokens the list of participating pools to query
     * @param maxAmount an optional bound on the rewards to claim (when partial claiming is required)
     * @param lpStats liquidity protection statistics store
     *
     * @return all pending rewards
     */
    function claimPendingRewards(
        address provider,
        IDSToken[] memory poolTokens,
        uint256 maxAmount,
        ILiquidityProtectionStats lpStats
    ) private returns (uint256) {
        uint256 reward = 0;

        uint256 length = poolTokens.length;
        for (uint256 i = 0; i < length && maxAmount > 0; ++i) {
            uint256 poolReward = claimPendingRewards(provider, poolTokens[i], maxAmount, lpStats);
            reward = reward.add(poolReward);

            if (maxAmount != MAX_UINT256) {
                maxAmount = maxAmount.sub(poolReward);
            }
        }

        return reward;
    }

    /**
     * @dev claims specific provider's pending rewards for a specific pool
     *
     * @param provider the owner of the liquidity
     * @param poolToken the pool to query
     * @param maxAmount an optional bound on the rewards to claim (when partial claiming is required)
     * @param lpStats liquidity protection statistics store
     *
     * @return reward all pending rewards
     */
    function claimPendingRewards(
        address provider,
        IDSToken poolToken,
        uint256 maxAmount,
        ILiquidityProtectionStats lpStats
    ) private returns (uint256) {
        uint256 reward = 0;
        PoolProgram memory program = poolProgram(poolToken);

        for (uint256 i = 0; i < program.reserveTokens.length && maxAmount > 0; ++i) {
            uint256 reserveReward =
                claimPendingRewards(provider, poolToken, program.reserveTokens[i], program, maxAmount, lpStats);
            reward = reward.add(reserveReward);

            if (maxAmount != MAX_UINT256) {
                maxAmount = maxAmount.sub(reserveReward);
            }
        }

        return reward;
    }

    /**
     * @dev claims specific provider's pending rewards for a specific pool/reserve
     *
     * @param provider the owner of the liquidity
     * @param poolToken the pool to query
     * @param reserveToken the reserve token representing the liquidity in the pool
     * @param program the pool program info
     * @param maxAmount an optional bound on the rewards to claim (when partial claiming is required)
     * @param lpStats liquidity protection statistics store
     *
     * @return reward all pending rewards
     */

    function claimPendingRewards(
        address provider,
        IDSToken poolToken,
        IERC20Token reserveToken,
        PoolProgram memory program,
        uint256 maxAmount,
        ILiquidityProtectionStats lpStats
    ) private returns (uint256) {
        // update all provider's pending rewards, in order to apply retroactive reward multipliers.
        (PoolRewards memory poolRewardsData, ProviderRewards memory providerRewards) =
            updateRewards(provider, poolToken, reserveToken, lpStats);

        // get full rewards and the respective rewards multiplier.
        (uint256 fullReward, uint32 multiplier) =
            fullRewards(provider, poolToken, reserveToken, poolRewardsData, providerRewards, program, lpStats);

        // mark any debt as repaid.
        providerRewards.baseRewardsDebt = 0;
        providerRewards.baseRewardsDebtMultiplier = 0;

        if (maxAmount != MAX_UINT256) {
            if (fullReward > maxAmount) {
                // get the amount of the actual base rewards that were claimed.
                if (multiplier == PPM_RESOLUTION) {
                    providerRewards.baseRewardsDebt = fullReward.sub(maxAmount);
                } else {
                    providerRewards.baseRewardsDebt = fullReward.sub(maxAmount).mul(PPM_RESOLUTION).div(multiplier);
                }

                // store the current multiplier for future retroactive rewards correction.
                providerRewards.baseRewardsDebtMultiplier = multiplier;

                // grant only maxAmount rewards.
                fullReward = maxAmount;

                maxAmount = 0;
            } else {
                maxAmount = maxAmount.sub(fullReward);
            }
        }

        // update pool rewards data total claimed rewards.
        _store.updatePoolRewardsData(
            poolToken,
            reserveToken,
            poolRewardsData.lastUpdateTime,
            poolRewardsData.rewardPerToken,
            poolRewardsData.totalClaimedRewards.add(fullReward)
        );

        // update provider rewards data with the remaining pending rewards and set the effective staking time to the
        // timestamp of the current block.
        _store.updateProviderRewardsData(
            provider,
            poolToken,
            reserveToken,
            providerRewards.rewardPerToken,
            0,
            providerRewards.totalClaimedRewards.add(fullReward),
            time(),
            providerRewards.baseRewardsDebt,
            providerRewards.baseRewardsDebtMultiplier
        );

        return fullReward;
    }

    /**
     * @dev returns the current rewards multiplier for a provider in a given pool
     *
     * @param provider the owner of the liquidity
     * @param poolToken the pool to query
     * @param reserveToken the reserve token representing the liquidity in the pool
     *
     * @return rewards multiplier
     */
    function rewardsMultiplier(address provider, IDSToken poolToken, IERC20Token reserveToken) external view returns (uint32) {
        ProviderRewards memory providerRewards = providerRewards(provider, poolToken, reserveToken);
        PoolProgram memory program = poolProgram(poolToken);
        return rewardsMultiplier(provider, providerRewards.effectiveStakingTime, program);
    }

    /**
     * @dev returns specific provider's total claimed rewards from all participating pools
     *
     * @param provider the owner of the liquidity
     *
     * @return total claimed rewards from all participating pools
     */
    function totalClaimedRewards(address provider) external view returns (uint256) {
        uint256 totalRewards = 0;

        ILiquidityProtectionStats lpStats = liquidityProtectionStats();
        IDSToken[] memory poolTokens = lpStats.providerPools(provider);

        for (uint256 i = 0; i < poolTokens.length; ++i) {
            IDSToken poolToken = poolTokens[i];
            PoolProgram memory program = poolProgram(poolToken);

            for (uint256 j = 0; j < program.reserveTokens.length; ++j) {
                IERC20Token reserveToken = program.reserveTokens[j];

                ProviderRewards memory providerRewards = providerRewards(provider, poolToken, reserveToken);

                totalRewards = totalRewards.add(providerRewards.totalClaimedRewards);
            }
        }

        return totalRewards;
    }

    /**
     * @dev claims pending rewards from all participating pools
     *
     * @return all claimed rewards
     */
    function claimRewards() external returns (uint256) {
        return claimRewards(msg.sender, liquidityProtectionStats());
    }

    /**
     * @dev claims specific provider's pending rewards from all participating pools
     *
     * @param provider the owner of the liquidity
     * @param lpStats liquidity protection statistics store
     *
     * @return all claimed rewards
     */
    function claimRewards(address provider, ILiquidityProtectionStats lpStats) private returns (uint256) {
        return claimRewards(provider, lpStats.providerPools(provider), MAX_UINT256, lpStats);
    }

    /**
     * @dev claims specific provider's pending rewards for a specific list of participating pools
     *
     * @param provider the owner of the liquidity
     * @param poolTokens the list of participating pools to query
     * @param maxAmount an optional cap on the rewards to claim
     * @param lpStats liquidity protection statistics store
     *
     * @return all pending rewards
     */
    function claimRewards(
        address provider,
        IDSToken[] memory poolTokens,
        uint256 maxAmount,
        ILiquidityProtectionStats lpStats
    ) private returns (uint256) {
        uint256 amount = claimPendingRewards(provider, poolTokens, maxAmount, lpStats);
        if (amount == 0) {
            return amount;
        }

        // make sure to update the last claim time so that it'll be taken into effect when calculating the next rewards
        // multiplier.
        _store.updateProviderLastClaimTime(provider);

        // mint the reward tokens directly to the provider.
        _networkTokenGovernance.mint(provider, amount);

        emit RewardsClaimed(provider, amount);

        return amount;
    }

    /**
     * @dev stakes specific pending rewards from all participating pools
     *
     * @param maxAmount an optional cap on the rewards to stake
     * @param poolToken the pool token representing the new rewards pool

     * @return all staked rewards and the ID of the new position
     */
    function stakeRewards(uint256 maxAmount, IDSToken poolToken) external returns (uint256, uint256) {
        return stakeRewards(msg.sender, maxAmount, poolToken, liquidityProtectionStats());
    }

    /**
     * @dev stakes specific provider's pending rewards from all participating pools
     *
     * @param provider the owner of the liquidity
     * @param maxAmount an optional cap on the rewards to stake
     * @param poolToken the pool token representing the new rewards pool
     * @param lpStats liquidity protection statistics store
     *
     * @return all staked rewards and the ID of the new position
     */
    function stakeRewards(
        address provider,
        uint256 maxAmount,
        IDSToken poolToken,
        ILiquidityProtectionStats lpStats
    ) private returns (uint256, uint256) {
        return stakeRewards(provider, lpStats.providerPools(provider), maxAmount, poolToken, lpStats);
    }

    /**
     * @dev claims and stakes specific provider's pending rewards for a specific list of participating pools
     *
     * @param provider the owner of the liquidity
     * @param poolTokens the list of participating pools to query
     * @param newPoolToken the pool token representing the new rewards pool
     * @param maxAmount an optional cap on the rewards to stake
     * @param lpStats liquidity protection statistics store
     *
     * @return all staked rewards and the ID of the new position
     */
    function stakeRewards(
        address provider,
        IDSToken[] memory poolTokens,
        uint256 maxAmount,
        IDSToken newPoolToken,
        ILiquidityProtectionStats lpStats
    ) private returns (uint256, uint256) {
        uint256 amount = claimPendingRewards(provider, poolTokens, maxAmount, lpStats);
        if (amount == 0) {
            return (amount, 0);
        }

        // approve the LiquidityProtection contract to pull the rewards.
        ILiquidityProtection liquidityProtection = liquidityProtection();
        _networkToken.safeApprove(address(liquidityProtection), amount);

        // mint the reward tokens directly to the staking contract, so that the LiquidityProtection could pull the
        // rewards and attribute them to the provider.
        _networkTokenGovernance.mint(address(this), amount);

        uint256 newId =
            liquidityProtection.addLiquidityFor(provider, newPoolToken, IERC20Token(address(_networkToken)), amount);

        // please note, that in order to incentivize staking, we won't be updating the time of the last claim, thus
        // preserving the rewards bonus multiplier.

        emit RewardsStaked(provider, newPoolToken, amount, newId);

        return (amount, newId);
    }

    /**
     * @dev store specific provider's pending rewards for future claims
     *
     * @param provider the owner of the liquidity
     * @param poolTokens the list of participating pools to query
     * @param lpStats liquidity protection statistics store
     *
     */
    function storeRewards(
        address provider,
        IDSToken[] memory poolTokens,
        ILiquidityProtectionStats lpStats
    ) private {
        uint256 length = poolTokens.length;
        for (uint256 i = 0; i < length; ++i) {
            storeRewards(provider, poolTokens[i], lpStats);
        }
    }

    /**
     * @dev store specific provider's pending rewards for future claims
     *
     * @param provider the owner of the liquidity
     * @param poolToken the list of participating pools to query
     * @param lpStats liquidity protection statistics store
     *
     */
    function storeRewards(
        address provider,
        IDSToken poolToken,
        ILiquidityProtectionStats lpStats
    ) private {
        PoolProgram memory program = poolProgram(poolToken);

        for (uint256 i = 0; i < program.reserveTokens.length; ++i) {
            IERC20Token reserveToken = program.reserveTokens[i];

            // update all provider's pending rewards, in order to apply retroactive reward multipliers.
            (PoolRewards memory poolRewardsData, ProviderRewards memory providerRewards) =
                updateRewards(provider, poolToken, reserveToken, lpStats);

            // get full rewards and the respective rewards multiplier.
            (uint256 fullReward, uint32 multiplier) =
                fullRewards(provider, poolToken, reserveToken, poolRewardsData, providerRewards, program, lpStats);

            // get the amount of the actual base rewards that were claimed.
            if (multiplier == PPM_RESOLUTION) {
                providerRewards.baseRewardsDebt = fullReward;
            } else {
                providerRewards.baseRewardsDebt = fullReward.mul(PPM_RESOLUTION).div(multiplier);
            }

            // update store data with the store pending rewards and set the last update time to the timestamp of the
            // current block.
            _store.updateProviderRewardsData(
                provider,
                poolToken,
                reserveToken,
                providerRewards.rewardPerToken,
                0,
                providerRewards.totalClaimedRewards,
                time(),
                providerRewards.baseRewardsDebt,
                multiplier
            );
        }
    }

    /**
     * @dev updates pending rewards for a list of providers
     *
     * @param providers owners of the liquidity
     */
    function updateRewards(address[] calldata providers) external {
        ILiquidityProtectionStats lpStats = liquidityProtectionStats();

        uint256 length = providers.length;
        for (uint256 i = 0; i < length; ++i) {
            updateRewards(providers[i], lpStats);
        }
    }

    /**
     * @dev updates pending rewards for a specific of provider
     *
     * @param provider the owner of the liquidity
     * @param lpStats liquidity protection statistics store
     */
    function updateRewards(address provider, ILiquidityProtectionStats lpStats) private {
        IDSToken[] memory poolTokens = lpStats.providerPools(provider);

        for (uint256 i = 0; i < poolTokens.length; ++i) {
            IDSToken poolToken = poolTokens[i];
            PoolProgram memory program = poolProgram(poolToken);

            for (uint256 j = 0; j < program.reserveTokens.length; ++j) {
                IERC20Token reserveToken = program.reserveTokens[j];
                updateRewards(provider, poolToken, reserveToken, lpStats);
            }
        }
    }

    /**
     * @dev returns the aggregated reward rate per-token
     *
     * @param poolToken the list of participating pools to query
     * @param reserveToken the reserve token representing the liquidity in the pool
     * @param poolRewardsData the rewards data of the pool
     * @param program the pool program info
     * @param lpStats liquidity protection statistics store
     *
     * @return the aggregated reward rate per-token
     */
    function rewardPerToken(
        IDSToken poolToken,
        IERC20Token reserveToken,
        PoolRewards memory poolRewardsData,
        PoolProgram memory program,
        ILiquidityProtectionStats lpStats
    ) internal view returns (uint256) {
        // if there is no longer any liquidity in this reserve, return the historic rate (i.e., rewards won't accrue).
        uint256 totalReserveAmount = lpStats.totalReserveAmount(poolToken, reserveToken);
        if (totalReserveAmount == 0) {
            return poolRewardsData.rewardPerToken;
        }

        // don't grant any rewards before the starting time of the program.
        uint256 currentTime = time();
        if (currentTime < program.startTime) {
            return 0;
        }

        uint256 stakingEndTime = Math.min(currentTime, program.endTime);
        uint256 stakingStartTime = Math.max(program.startTime, poolRewardsData.lastUpdateTime);

        // since we will be dividing by the total amount of protected tokens in units of wei, we can encounter cases
        // where the total amount in the denominator is higher than the product of the rewards rate and staking duration.
        // in order to avoid this imprecision, we will amplify the reward rate by the units amount.
        return
            poolRewardsData.rewardPerToken.add( // the aggregated reward rate
                stakingEndTime
                    .sub(stakingStartTime) // the duration of the staking
                    .mul(program.rewardRate) // multiplied by the rate
                    .mul(REWARD_RATE_FACTOR) // and factored to increase precision
                    .mul(rewardShare(reserveToken, program)) // and applied the specific token share of the whole reward
                    .div(totalReserveAmount.mul(PPM_RESOLUTION)) // and divided by the total protected tokens amount in the pool
            );
    }

    /**
     * @dev returns the base rewards since the last claim
     *
     * @param provider the owner of the liquidity
     * @param poolToken the list of participating pools to query
     * @param reserveToken the reserve token representing the liquidity in the pool
     * @param poolRewardsData the rewards data of the pool
     * @param providerRewards the rewards data of the provider
     * @param program the pool program info
     * @param lpStats liquidity protection statistics store
     *
     * @return the base rewards since the last claim
     */
    function baseRewards(
        address provider,
        IDSToken poolToken,
        IERC20Token reserveToken,
        PoolRewards memory poolRewardsData,
        ProviderRewards memory providerRewards,
        PoolProgram memory program,
        ILiquidityProtectionStats lpStats
    ) internal view returns (uint256) {
        uint256 totalProviderAmount = lpStats.totalProviderAmount(provider, poolToken, reserveToken);
        uint256 newRewardPerToken = rewardPerToken(poolToken, reserveToken, poolRewardsData, program, lpStats);

        return
            totalProviderAmount // the protected tokens amount held by the provider
                .mul(newRewardPerToken.sub(providerRewards.rewardPerToken)) // multiplied by the difference between the previous and the current rate
                .div(REWARD_RATE_FACTOR); // and factored back
    }

    /**
     * @dev returns the full rewards since the last claim
     *
     * @param provider the owner of the liquidity
     * @param poolToken the list of participating pools to query
     * @param reserveToken the reserve token representing the liquidity in the pool
     * @param poolRewardsData the rewards data of the pool
     * @param providerRewards the rewards data of the provider
     * @param program the pool program info
     * @param lpStats liquidity protection statistics store
     *
     * @return full rewards and the respective rewards multiplier
     */
    function fullRewards(
        address provider,
        IDSToken poolToken,
        IERC20Token reserveToken,
        PoolRewards memory poolRewardsData,
        ProviderRewards memory providerRewards,
        PoolProgram memory program,
        ILiquidityProtectionStats lpStats
    ) internal view returns (uint256, uint32) {
        // calculate the claimable base rewards (since the last claim).
        uint256 newBaseRewards =
            baseRewards(provider, poolToken, reserveToken, poolRewardsData, providerRewards, program, lpStats);

        // make sure that we aren't exceeding the reward rate for any reason.
        verifyBaseReward(newBaseRewards, providerRewards.effectiveStakingTime, reserveToken, program);

        // calculate pending rewards and apply the rewards multiplier.
        uint32 multiplier = rewardsMultiplier(provider, providerRewards.effectiveStakingTime, program);
        uint256 fullReward = providerRewards.pendingBaseRewards.add(newBaseRewards);
        if (multiplier != PPM_RESOLUTION) {
            fullReward = fullReward.mul(multiplier).div(PPM_RESOLUTION);
        }

        // add any debt, while applying the best retractive multiplier.
        fullReward = fullReward.add(
            applyHigherMultiplier(
                providerRewards.baseRewardsDebt,
                multiplier,
                providerRewards.baseRewardsDebtMultiplier
            )
        );

        // make sure that we aren't exceeding the full reward rate for any reason.
        verifyFullReward(fullReward, reserveToken, poolRewardsData, program);

        return (fullReward, multiplier);
    }

    /**
     * @dev updates pool and provider rewards. this function is called during every liquidity changes
     *
     * @param provider the owner of the liquidity
     * @param poolToken the pool token representing the rewards pool
     * @param reserveToken the reserve token representing the liquidity in the pool
     * @param lpStats liquidity protection statistics store
     */
    function updateRewards(
        address provider,
        IDSToken poolToken,
        IERC20Token reserveToken,
        ILiquidityProtectionStats lpStats
    ) private returns (PoolRewards memory, ProviderRewards memory) {
        PoolProgram memory program = poolProgram(poolToken);

        // calculate the new reward rate per-token and update it in the store.
        PoolRewards memory poolRewardsData = poolRewards(poolToken, reserveToken);

        // rewardPerToken must be calculated with the previous value of lastUpdateTime.
        poolRewardsData.rewardPerToken = rewardPerToken(poolToken, reserveToken, poolRewardsData, program, lpStats);
        poolRewardsData.lastUpdateTime = Math.min(time(), program.endTime);

        _store.updatePoolRewardsData(
            poolToken,
            reserveToken,
            poolRewardsData.lastUpdateTime,
            poolRewardsData.rewardPerToken,
            poolRewardsData.totalClaimedRewards
        );

        // update provider's rewards with the newly claimable base rewards and the new reward rate per-token.
        ProviderRewards memory providerRewards = providerRewards(provider, poolToken, reserveToken);

        // if this is the first liquidity provision - set the effective staking time to the current time.
        if (
            providerRewards.effectiveStakingTime == 0 &&
            lpStats.totalProviderAmount(provider, poolToken, reserveToken) == 0
        ) {
            providerRewards.effectiveStakingTime = time();
        }

        // pendingBaseRewards must be calculated with the previous value of providerRewards.rewardPerToken.
        providerRewards.pendingBaseRewards = providerRewards.pendingBaseRewards.add(
            baseRewards(provider, poolToken, reserveToken, poolRewardsData, providerRewards, program, lpStats)
        );
        providerRewards.rewardPerToken = poolRewardsData.rewardPerToken;

        _store.updateProviderRewardsData(
            provider,
            poolToken,
            reserveToken,
            providerRewards.rewardPerToken,
            providerRewards.pendingBaseRewards,
            providerRewards.totalClaimedRewards,
            providerRewards.effectiveStakingTime,
            providerRewards.baseRewardsDebt,
            providerRewards.baseRewardsDebtMultiplier
        );

        return (poolRewardsData, providerRewards);
    }

    /**
     * @dev returns the specific reserve token's share of all rewards
     *
     * @param reserveToken the reserve token representing the liquidity in the pool
     * @param program the pool program info
     */
    function rewardShare(IERC20Token reserveToken, PoolProgram memory program) private pure returns (uint32) {
        if (reserveToken == program.reserveTokens[0]) {
            return program.rewardShares[0];
        }

        return program.rewardShares[1];
    }

    /**
     * @dev returns the rewards multiplier for the specific provider
     *
     * @param provider the owner of the liquidity
     * @param stakingStartTime the staking time in the pool
     * @param program the pool program info
     *
     * @return the rewards multiplier for the specific provider
     */
    function rewardsMultiplier(
        address provider,
        uint256 stakingStartTime,
        PoolProgram memory program
    ) private view returns (uint32) {
        uint256 effectiveStakingEndTime = Math.min(time(), program.endTime);
        uint256 effectiveStakingStartTime =
            Math.max( // take the latest of actual staking start time and the latest multiplier reset
                Math.max(stakingStartTime, program.startTime), // don't count staking before the start of the program
                Math.max(_lastRemoveTimes.checkpoint(provider), _store.providerLastClaimTime(provider)) // get the latest multiplier reset timestamp
            );

        // check that the staking range is valid. for example, it can be invalid when calculating the multiplier when
        // the staking has started before the start of the program, in which case the effective staking start time will
        // be in the future, compared to the effective staking end time (which will be the time of the current block).
        if (effectiveStakingStartTime >= effectiveStakingEndTime) {
            return PPM_RESOLUTION;
        }

        uint256 effectiveStakingDuration = effectiveStakingEndTime.sub(effectiveStakingStartTime);

        // given x representing the staking duration (in seconds), the resulting multiplier (in PPM) is:
        // * for 0 <= x <= 1 weeks: 100% PPM
        // * for 1 <= x <= 2 weeks: 125% PPM
        // * for 2 <= x <= 3 weeks: 150% PPM
        // * for 3 <= x <= 4 weeks: 175% PPM
        // * for x > 4 weeks: 200% PPM
        return PPM_RESOLUTION + MULTIPLIER_INCREMENT * uint32(Math.min(effectiveStakingDuration.div(1 weeks), 4));
    }

    /**
     * @dev returns the pool program for a specific pool
     *
     * @param poolToken the pool token representing the rewards pool
     *
     * @return the pool program for a specific pool
     */
    function poolProgram(IDSToken poolToken) internal view returns (PoolProgram memory) {
        PoolProgram memory program;
        (program.startTime, program.endTime, program.rewardRate, program.reserveTokens, program.rewardShares) = _store
            .poolProgram(poolToken);

        return program;
    }

    /**
     * @dev returns pool rewards for a specific pool and reserve
     *
     * @param poolToken the pool token representing the rewards pool
     * @param reserveToken the reserve token representing the liquidity in the pool
     *
     * @return pool rewards for a specific pool and reserve
     */
    function poolRewards(IDSToken poolToken, IERC20Token reserveToken) internal view returns (PoolRewards memory) {
        PoolRewards memory data;
        (data.lastUpdateTime, data.rewardPerToken, data.totalClaimedRewards) = _store.poolRewards(
            poolToken,
            reserveToken
        );

        return data;
    }

    /**
     * @dev returns provider rewards for a specific pool and reserve
     *
     * @param provider the owner of the liquidity
     * @param poolToken the pool token representing the rewards pool
     * @param reserveToken the reserve token representing the liquidity in the pool
     *
     * @return provider rewards for a specific pool and reserve
     */
    function providerRewards(
        address provider,
        IDSToken poolToken,
        IERC20Token reserveToken
    ) internal view returns (ProviderRewards memory) {
        ProviderRewards memory data;
        (
            data.rewardPerToken,
            data.pendingBaseRewards,
            data.totalClaimedRewards,
            data.effectiveStakingTime,
            data.baseRewardsDebt,
            data.baseRewardsDebtMultiplier
        ) = _store.providerRewards(provider, poolToken, reserveToken);

        return data;
    }

    /**
     * @dev applies the best of two rewards multipliers on the provided amount
     *
     * @param amount the amount of the reward
     * @param multiplier1 the first multiplier
     * @param multiplier2 the second multiplier
     *
     * @return new reward amount
     */
    function applyHigherMultiplier(
        uint256 amount,
        uint32 multiplier1,
        uint32 multiplier2
    ) private pure returns (uint256) {
        uint256 bestMultiplier = Math.max(multiplier1, multiplier2);
        if (bestMultiplier == PPM_RESOLUTION) {
            return amount;
        }

        return amount.mul(bestMultiplier).div(PPM_RESOLUTION);
    }

    /**
     * @dev performs a sanity check on the newly claimable base rewards
     *
     * @param baseReward the base reward to check
     * @param stakingStartTime the staking time in the pool
     * @param reserveToken the reserve token representing the liquidity in the pool
     * @param program the pool program info
     */
    function verifyBaseReward(
        uint256 baseReward,
        uint256 stakingStartTime,
        IERC20Token reserveToken,
        PoolProgram memory program
    ) private view {
        // don't grant any rewards before the starting time of the program or for stakes after the end of the program.
        uint256 currentTime = time();
        if (currentTime < program.startTime || stakingStartTime >= program.endTime) {
            require(baseReward == 0, "ERR_BASE_REWARD_TOO_HIGH");

            return;
        }

        uint256 effectiveStakingStartTime = Math.max(stakingStartTime, program.startTime);
        uint256 effectiveStakingEndTime = Math.min(currentTime, program.endTime);

        // make sure that we aren't exceeding the base reward rate for any reason.
        require(
            baseReward <=
                program
                    .rewardRate
                    .mul(effectiveStakingEndTime.sub(effectiveStakingStartTime))
                    .mul(rewardShare(reserveToken, program))
                    .div(PPM_RESOLUTION),
            "ERR_BASE_REWARD_RATE_TOO_HIGH"
        );
    }

    /**
     * @dev performs a sanity check on the newly claimable full rewards
     *
     * @param fullReward the full reward to check
     * @param reserveToken the reserve token representing the liquidity in the pool
     * @param poolRewardsData the rewards data of the pool
     * @param program the pool program info
     */
    function verifyFullReward(
        uint256 fullReward,
        IERC20Token reserveToken,
        PoolRewards memory poolRewardsData,
        PoolProgram memory program
    ) private pure {
        uint256 maxClaimableReward =
            (
                program
                    .rewardRate
                    .mul(program.endTime.sub(program.startTime))
                    .mul(rewardShare(reserveToken, program))
                    .mul(MAX_MULTIPLIER)
                    .div(PPM_RESOLUTION)
                    .div(PPM_RESOLUTION)
            )
                .sub(poolRewardsData.totalClaimedRewards);

        // make sure that we aren't exceeding the full reward rate for any reason.
        require(fullReward <= maxClaimableReward, "ERR_REWARD_RATE_TOO_HIGH");
    }

    /**
     * @dev returns the liquidity protection stats data contract
     *
     * @return the liquidity protection store data contract
     */
    function liquidityProtectionStats() internal view returns (ILiquidityProtectionStats) {
        return liquidityProtection().stats();
    }

    /**
     * @dev returns the liquidity protection contract
     *
     * @return the liquidity protection contract
     */
    function liquidityProtection() internal view returns (ILiquidityProtection) {
        return ILiquidityProtection(addressOf(LIQUIDITY_PROTECTION));
    }
}
