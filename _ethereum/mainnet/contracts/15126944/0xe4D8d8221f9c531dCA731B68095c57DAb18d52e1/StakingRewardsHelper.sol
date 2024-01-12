// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./IERC20.sol";
import "./IERC20Metadata.sol";
import "./SafeERC20.sol";
import "./ITokenInterface.sol";
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
        uint256 supplyRatePerBlock;
        uint256 exchangeRate;
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
            uint256 supplyRatePerBlock = ITokenInterface(stakingToken)
                .supplyRatePerBlock();
            uint256 exchangeRate = ITokenInterface(stakingToken)
                .exchangeRateStored();
            stakingRewardRates[i] = StakingInfo({
                stakingTokenAddress: stakingToken,
                totalSupply: totalSupply,
                supplyRatePerBlock: supplyRatePerBlock,
                exchangeRate: exchangeRate,
                rewardRates: rewardRates
            });
        }
        return stakingRewardRates;
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    /**
     * @notice Mint and stake tokens into staking rewards
     * @param underlying The underlying token
     * @param amount The amount
     */
    function stake(address underlying, uint256 amount) public {
        require(amount > 0, "invalid amount");
        address stakingToken = factory.getStakingToken(underlying);
        require(stakingToken != address(0), "invalid staking token");
        address stakingRewards = factory.getStakingRewards(stakingToken);
        require(stakingRewards != address(0), "staking rewards not exist");

        // Get funds from user.
        IERC20(underlying).safeTransferFrom(msg.sender, address(this), amount);

        // Mint
        IERC20(underlying).approve(stakingToken, amount);
        require(ITokenInterface(stakingToken).mint(amount) == 0, "mint failed");

        // Stake to staking rewards.
        uint256 balance = IERC20(stakingToken).balanceOf(address(this));
        IERC20(stakingToken).approve(stakingRewards, balance);
        StakingRewardsInterface(stakingRewards).stakeFor(msg.sender, balance);

        assert(IERC20(stakingToken).balanceOf(address(this)) == 0);
    }

    /**
     * @notice Unstake tokens from staking rewards and redeem
     * @param stakingRewards The staking rewards
     * @param amount The amount
     */
    function unstake(address stakingRewards, uint256 amount) public {
        require(amount > 0, "invalid amount");
        address stakingToken = StakingRewardsInterface(stakingRewards)
            .getStakingToken();
        require(stakingToken != address(0), "invalid staking token");
        address underlying = ITokenInterface(stakingToken).underlying();
        require(underlying != address(0), "invalid underlying");

        // Withdraw from staking rewards.
        StakingRewardsInterface(stakingRewards).withdrawFor(msg.sender, amount);

        // Redeem
        require(
            ITokenInterface(stakingToken).redeem(amount) == 0,
            "redeem failed"
        );

        // Send funds to user.
        uint256 balance = IERC20(underlying).balanceOf(address(this));
        IERC20(underlying).transfer(msg.sender, balance);

        assert(IERC20(underlying).balanceOf(address(this)) == 0);
    }

    /**
     * @notice Exit all staking rewards
     */
    function exitAll() public {
        address[] memory allStakingRewards = factory.getAllStakingRewards();
        exit(allStakingRewards);
    }

    /**
     * @notice Exit staking rewards
     * @param stakingRewards The list of staking rewards
     */
    function exit(address[] memory stakingRewards) public {
        for (uint256 i = 0; i < stakingRewards.length; i++) {
            uint256 balance = StakingRewardsInterface(stakingRewards[i])
                .balanceOf(msg.sender);
            unstake(stakingRewards[i], balance);
            StakingRewardsInterface(stakingRewards[i]).getRewardFor(msg.sender);
        }
    }

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
