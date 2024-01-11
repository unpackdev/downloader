// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./IERC20.sol";
import "./IERC20Metadata.sol";
import "./SafeERC20.sol";
import "./StakingRewardsInterface.sol";
import "./StakingRewardsFactoryInterface.sol";

contract StakingRewardsHelper is Ownable {
    using SafeERC20 for IERC20;

    StakingRewardsFactoryInterface public immutable factory;

    /**
     * @notice Emitted when tokens are seized
     */
    event TokenSeized(address token, uint256 amount);

    /* ========== CONSTRUCTOR ========== */

    constructor(address _factory) {
        factory = StakingRewardsFactoryInterface(_factory);
    }

    /* ========== VIEWS ========== */

    struct RewardTokenInfo {
        address rewardTokenAddress;
        string rewardTokenSymbol;
        uint8 rewardTokenDecimals;
    }

    struct RewardClaimable {
        RewardTokenInfo rewardToken;
        uint256 amount;
    }

    struct UserStaked {
        address stakingTokenAddress;
        uint256 balance;
    }

    struct StakingInfo {
        address stakingTokenAddress;
        uint256 totalSupply;
        RewardRate[] rewardRates;
    }

    struct RewardRate {
        address rewardTokenAddress;
        uint256 rate;
    }

    /**
     * @notice Getthe reward token info
     * @param rewardToken The reward token
     * @return The reward token info
     */
    function getRewardTokenInfo(address rewardToken)
        public
        view
        returns (RewardTokenInfo memory)
    {
        return
            RewardTokenInfo({
                rewardTokenAddress: rewardToken,
                rewardTokenSymbol: IERC20Metadata(rewardToken).symbol(),
                rewardTokenDecimals: IERC20Metadata(rewardToken).decimals()
            });
    }

    /**
     * @notice Get user claimable rewards
     * @param account The account
     * @param rewardTokens The list of reward tokens
     * @return The list of user claimable rewards
     */
    function getUserClaimableRewards(
        address account,
        address[] calldata rewardTokens
    ) public view returns (RewardClaimable[] memory) {
        RewardClaimable[] memory rewardsClaimable = new RewardClaimable[](
            rewardTokens.length
        );

        address[] memory allStakingRewards = factory.getAllStakingRewards();
        for (uint256 i = 0; i < rewardTokens.length; i++) {
            uint256 amount;
            for (uint256 j = 0; j < allStakingRewards.length; j++) {
                address stakingRewards = allStakingRewards[j];
                amount += StakingRewardsInterface(stakingRewards).earned(
                    rewardTokens[i],
                    account
                );
            }

            rewardsClaimable[i] = RewardClaimable({
                rewardToken: getRewardTokenInfo(rewardTokens[i]),
                amount: amount
            });
        }
        return rewardsClaimable;
    }

    /**
     * @notice Get user staked info
     * @param account The account
     * @return The list of user staked info
     */
    function getUserStaked(address account)
        public
        view
        returns (UserStaked[] memory)
    {
        address[] memory allStakingRewards = factory.getAllStakingRewards();
        UserStaked[] memory stakedInfo = new UserStaked[](
            allStakingRewards.length
        );
        for (uint256 i = 0; i < allStakingRewards.length; i++) {
            address stakingRewards = allStakingRewards[i];
            address stakingToken = StakingRewardsInterface(stakingRewards)
                .getStakingToken();
            uint256 balance = StakingRewardsInterface(stakingRewards).balanceOf(
                account
            );
            stakedInfo[i] = UserStaked({
                stakingTokenAddress: stakingToken,
                balance: balance
            });
        }
        return stakedInfo;
    }

    /**
     * @notice Get all the staking info
     * @return The list of staking info
     */
    function getStakingInfo() public view returns (StakingInfo[] memory) {
        address[] memory allStakingRewards = factory.getAllStakingRewards();
        StakingInfo[] memory stakingRewardRates = new StakingInfo[](
            allStakingRewards.length
        );
        for (uint256 i = 0; i < allStakingRewards.length; i++) {
            address stakingRewards = allStakingRewards[i];
            address[] memory allRewardTokens = StakingRewardsInterface(
                stakingRewards
            ).getAllRewardsTokens();

            RewardRate[] memory rewardRates = new RewardRate[](
                allRewardTokens.length
            );
            for (uint256 j = 0; j < allRewardTokens.length; j++) {
                address rewardToken = allRewardTokens[j];
                uint256 rate = StakingRewardsInterface(stakingRewards)
                    .getRewardRate(rewardToken);
                rewardRates[j] = RewardRate({
                    rewardTokenAddress: rewardToken,
                    rate: rate
                });
            }

            address stakingToken = StakingRewardsInterface(stakingRewards)
                .getStakingToken();
            uint256 totalSupply = StakingRewardsInterface(stakingRewards)
                .totalSupply();
            stakingRewardRates[i] = StakingInfo({
                stakingTokenAddress: stakingToken,
                totalSupply: totalSupply,
                rewardRates: rewardRates
            });
        }
        return stakingRewardRates;
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    /**
     * @notice Claim all rewards
     */
    function claimAllRewards() public {
        address[] memory allStakingRewards = factory.getAllStakingRewards();
        claimRewards(allStakingRewards);
    }

    /**
     * @notice Claim rewards by given staking rewards
     * @param stakingRewards The list of staking rewards
     */
    function claimRewards(address[] memory stakingRewards) public {
        for (uint256 i = 0; i < stakingRewards.length; i++) {
            StakingRewardsInterface(stakingRewards[i]).getRewardFor(msg.sender);
        }
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    /**
     * @notice Seize tokens in this contract.
     * @param token The token
     * @param amount The amount
     */
    function seize(address token, uint256 amount) external onlyOwner {
        IERC20(token).safeTransfer(owner(), amount);
        emit TokenSeized(token, amount);
    }
}
