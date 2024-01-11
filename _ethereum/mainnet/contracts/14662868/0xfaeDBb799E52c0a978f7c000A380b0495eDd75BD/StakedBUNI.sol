// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;
pragma abicoder v2;

import "./ERC20Detailed.sol";
import "./IERC20Upgradeable.sol";

import "./DistributionTypes.sol";
import "./SafeMath.sol";
import "./SafeERC20Upgradeable.sol";

import "./DistributionManager.sol";
import "./IStaked.sol";
import "./ReentrancyGuardUpgradeable.sol";

contract StakedBUNI is
    IStaked,
    ReentrancyGuardUpgradeable,
    ERC20Detailed,
    DistributionManager
{
    using SafeMath for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    address public stakedToken;
    address public rewardToken;

    address public rewardVault;

    mapping(address => uint256) public stakerRewardsToClaim;

    /**
     * @dev Called by the proxy contract
     **/
    function initialize(
        address _stakedToken,
        address _rewardToken,
        address _rewardVault,
        uint128 distributionDuration
    ) external initializer {
        __ERC20Detailed_init("Staked BEND/ETH UNI", "stkBUNI", 18);
        __DistributionManager_init(distributionDuration);
        __ReentrancyGuard_init();
        stakedToken = _stakedToken;
        rewardToken = _rewardToken;
        rewardVault = _rewardVault;
    }

    /**
     * @dev Configures the distribution of rewards for a list of assets
     * @param emissionPerSecond Representing the total rewards distributed per second per asset unit
     **/

    function configure(uint128 emissionPerSecond) external override onlyOwner {
        DistributionTypes.AssetConfigInput[]
            memory assetsConfigInput = new DistributionTypes.AssetConfigInput[](
                1
            );
        assetsConfigInput[0].emissionPerSecond = emissionPerSecond;
        assetsConfigInput[0].totalStaked = totalSupply();
        assetsConfigInput[0].underlyingAsset = address(this);
        _configureAssets(assetsConfigInput);
    }

    function stake(uint256 amount) external override nonReentrant {
        require(amount != 0, "INVALID_ZERO_AMOUNT");
        uint256 balanceOfUser = balanceOf(msg.sender);

        uint256 accruedRewards = _updateUserAssetInternal(
            msg.sender,
            address(this),
            balanceOfUser,
            totalSupply()
        );
        if (accruedRewards != 0) {
            emit RewardsAccrued(msg.sender, accruedRewards);
            stakerRewardsToClaim[msg.sender] = stakerRewardsToClaim[msg.sender]
                .add(accruedRewards);
        }

        IERC20Upgradeable(stakedToken).safeTransferFrom(
            msg.sender,
            address(this),
            amount
        );

        _mint(msg.sender, amount);

        emit Staked(msg.sender, amount);
    }

    /**
     * @dev Redeems staked tokens, and stop earning rewards
     * @param amount Amount to redeem
     **/
    function redeem(uint256 amount) external override nonReentrant {
        require(amount != 0, "INVALID_ZERO_AMOUNT");

        uint256 balanceOfMessageSender = balanceOf(msg.sender);

        uint256 amountToRedeem = (amount > balanceOfMessageSender)
            ? balanceOfMessageSender
            : amount;

        _updateCurrentUnclaimedRewards(
            msg.sender,
            balanceOfMessageSender,
            true
        );

        _burn(msg.sender, amountToRedeem);

        IERC20Upgradeable(stakedToken).safeTransfer(msg.sender, amountToRedeem);

        emit Redeem(msg.sender, amountToRedeem);
    }

    /**
     * @dev Claims an `amount` of `REWARD_TOKEN` to the address `to`
     * @param amount Amount to stake
     **/
    function claim(uint256 amount) external override nonReentrant {
        require(amount != 0, "INVALID_ZERO_AMOUNT");
        uint256 newTotalRewards = _updateCurrentUnclaimedRewards(
            msg.sender,
            balanceOf(msg.sender),
            false
        );
        uint256 amountToClaim = (amount == type(uint256).max)
            ? newTotalRewards
            : amount;
        stakerRewardsToClaim[msg.sender] = newTotalRewards.sub(
            amountToClaim,
            "INVALID_AMOUNT"
        );

        IERC20Upgradeable(rewardToken).safeTransferFrom(
            rewardVault,
            msg.sender,
            amountToClaim
        );

        emit RewardsClaimed(msg.sender, amountToClaim);
    }

    /**
     * @dev Internal ERC20 _transfer of the tokenized staked tokens
     * @param from Address to transfer from
     * @param to Address to transfer to
     * @param amount Amount to transfer
     **/
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        uint256 balanceOfFrom = balanceOf(from);
        // Sender
        _updateCurrentUnclaimedRewards(from, balanceOfFrom, true);

        // Recipient
        if (from != to) {
            uint256 balanceOfTo = balanceOf(to);
            _updateCurrentUnclaimedRewards(to, balanceOfTo, true);
        }

        super._transfer(from, to, amount);
    }

    /**
     * @dev Updates the user state related with his accrued rewards
     * @param user Address of the user
     * @param userBalance The current balance of the user
     * @param updateStorage Boolean flag used to update or not the stakerRewardsToClaim of the user
     * @return The unclaimed rewards that were added to the total accrued
     **/
    function _updateCurrentUnclaimedRewards(
        address user,
        uint256 userBalance,
        bool updateStorage
    ) internal returns (uint256) {
        uint256 accruedRewards = _updateUserAssetInternal(
            user,
            address(this),
            userBalance,
            totalSupply()
        );
        uint256 unclaimedRewards = stakerRewardsToClaim[user].add(
            accruedRewards
        );

        if (accruedRewards != 0) {
            if (updateStorage) {
                stakerRewardsToClaim[user] = unclaimedRewards;
            }
            emit RewardsAccrued(user, accruedRewards);
        }

        return unclaimedRewards;
    }

    /**
     * @dev Return the total rewards pending to claim by an staker
     * @param staker The staker address
     * @return The rewards
     */
    function claimableRewards(address staker)
        external
        view
        override
        returns (uint256)
    {
        DistributionTypes.UserStakeInput[]
            memory userStakeInputs = new DistributionTypes.UserStakeInput[](1);
        userStakeInputs[0] = DistributionTypes.UserStakeInput({
            underlyingAsset: address(this),
            stakedByUser: balanceOf(staker),
            totalStaked: totalSupply()
        });
        return
            stakerRewardsToClaim[staker].add(
                _getUnclaimedRewards(staker, userStakeInputs)
            );
    }

    function apr() external view returns (uint256) {
        if (totalSupply() == 0) {
            return 0;
        }
        uint256 _bendAmount = IERC20Upgradeable(rewardToken).balanceOf(
            stakedToken
        );
        uint256 _stakedVaueInBend = ((2 * _bendAmount) * totalSupply()) /
            IERC20Upgradeable(stakedToken).totalSupply();
        uint256 _oneYearBendEmission = assets[address(this)].emissionPerSecond *
            31536000;
        return (_oneYearBendEmission * 10**PRECISION) / _stakedVaueInBend;
    }
}
