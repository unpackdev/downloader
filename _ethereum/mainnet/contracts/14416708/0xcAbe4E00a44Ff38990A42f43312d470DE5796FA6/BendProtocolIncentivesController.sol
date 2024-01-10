// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;
pragma abicoder v2;

import "./SafeMath.sol";
import "./SafeERC20Upgradeable.sol";
import "./DistributionTypes.sol";

import "./DistributionManager.sol";

import "./IERC20Upgradeable.sol";

import "./IScaledBalanceToken.sol";
import "./IIncentivesController.sol";

/**
 * @title BendProtocolIncentivesController
 * @notice Distributor contract for rewards to the Bend protocol
 * @author Bend
 **/
contract BendProtocolIncentivesController is
    IIncentivesController,
    DistributionManager
{
    using SafeMath for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    IERC20Upgradeable public REWARD_TOKEN;
    address public REWARDS_VAULT;

    mapping(address => uint256) internal usersUnclaimedRewards;
    mapping(address => bool) public authorizedAssets;

    /**
     * @dev initial and configrate contract
     * @param _rewardToken The reward token to incentivize
     * @param _rewardsVault The vault of reward token
     * @param _distributionDuration  Duration of the reward distribution
     */
    function initialize(
        address _rewardToken,
        address _rewardsVault,
        uint128 _distributionDuration
    ) external initializer {
        __DistributionManager_init(_distributionDuration);
        REWARD_TOKEN = IERC20Upgradeable(_rewardToken);
        REWARDS_VAULT = _rewardsVault;
    }

    /**
     * @dev Configure assets for a certain rewards emission
     * @param _assets The assets to incentivize
     * @param _emissionsPerSecond The emission for each asset
     */
    function configureAssets(
        IScaledBalanceToken[] calldata _assets,
        uint256[] calldata _emissionsPerSecond
    ) external override onlyOwner {
        require(
            _assets.length == _emissionsPerSecond.length,
            "INVALID_CONFIGURATION"
        );

        DistributionTypes.AssetConfigInput[]
            memory assetsConfig = new DistributionTypes.AssetConfigInput[](
                _assets.length
            );

        for (uint256 i = 0; i < _assets.length; i++) {
            authorizedAssets[address(_assets[i])] = true;
            assetsConfig[i].underlyingAsset = address(_assets[i]);
            assetsConfig[i].emissionPerSecond = uint128(_emissionsPerSecond[i]);

            require(
                assetsConfig[i].emissionPerSecond == _emissionsPerSecond[i],
                "INVALID_CONFIGURATION"
            );

            assetsConfig[i].totalStaked = _assets[i].scaledTotalSupply();
        }
        _configureAssets(assetsConfig);
    }

    /**
     * @dev Called by the corresponding asset on any update that affects the rewards distribution
     * @param _user The address of the user
     * @param _totalSupply The total supply of the asset in the lending pool
     * @param _userBalance The balance of the user of the asset in the lending pool
     **/
    function handleAction(
        address _user,
        uint256 _totalSupply,
        uint256 _userBalance
    ) external override {
        require(authorizedAssets[msg.sender], "Sender Unauthorized");
        uint256 accruedRewards = _updateUserAssetInternal(
            _user,
            msg.sender,
            _userBalance,
            _totalSupply
        );
        if (accruedRewards != 0) {
            usersUnclaimedRewards[_user] = usersUnclaimedRewards[_user].add(
                accruedRewards
            );
            emit RewardsAccrued(_user, accruedRewards);
        }
    }

    /**
     * @dev Returns the total of rewards of an user, already accrued + not yet accrued
     * @param _assets The assets to incentivize
     * @param _user The address of the user
     * @return The rewards
     **/
    function getRewardsBalance(
        IScaledBalanceToken[] calldata _assets,
        address _user
    ) external view override returns (uint256) {
        uint256 unclaimedRewards = usersUnclaimedRewards[_user];

        DistributionTypes.UserStakeInput[]
            memory userState = new DistributionTypes.UserStakeInput[](
                _assets.length
            );
        for (uint256 i = 0; i < _assets.length; i++) {
            userState[i].underlyingAsset = address(_assets[i]);
            (
                userState[i].stakedByUser,
                userState[i].totalStaked
            ) = IScaledBalanceToken(_assets[i]).getScaledUserBalanceAndSupply(
                _user
            );
        }
        unclaimedRewards = unclaimedRewards.add(
            _getUnclaimedRewards(_user, userState)
        );
        return unclaimedRewards;
    }

    /**

     * @dev returns the unclaimed rewards of the user
     * @param _user the address of the user
     * @return the unclaimed user rewards
     */
    function getUserUnclaimedRewards(address _user)
        external
        view
        override
        returns (uint256)
    {
        return usersUnclaimedRewards[_user];
    }

    /**
     * @dev Claims reward for an user, on all the assets of the lending pool, accumulating the pending rewards
     * @param _assets The assets to incentivize
     * @param _amount Amount of rewards to claim
     * @return Rewards claimed
     **/
    function claimRewards(
        IScaledBalanceToken[] calldata _assets,
        uint256 _amount
    ) external override returns (uint256) {
        if (_amount == 0) {
            return 0;
        }
        address user = msg.sender;
        uint256 unclaimedRewards = usersUnclaimedRewards[user];

        DistributionTypes.UserStakeInput[]
            memory userState = new DistributionTypes.UserStakeInput[](
                _assets.length
            );
        for (uint256 i = 0; i < _assets.length; i++) {
            userState[i].underlyingAsset = address(_assets[i]);
            (
                userState[i].stakedByUser,
                userState[i].totalStaked
            ) = IScaledBalanceToken(_assets[i]).getScaledUserBalanceAndSupply(
                user
            );
        }

        uint256 accruedRewards = _claimRewards(user, userState);
        if (accruedRewards != 0) {
            unclaimedRewards = unclaimedRewards.add(accruedRewards);
            emit RewardsAccrued(user, accruedRewards);
        }

        if (unclaimedRewards == 0) {
            return 0;
        }

        uint256 amountToClaim = _amount > unclaimedRewards
            ? unclaimedRewards
            : _amount;
        usersUnclaimedRewards[user] = unclaimedRewards - amountToClaim; // Safe due to the previous line

        IERC20Upgradeable(REWARD_TOKEN).safeTransferFrom(
            REWARDS_VAULT,
            msg.sender,
            amountToClaim
        );

        emit RewardsClaimed(msg.sender, amountToClaim);

        return amountToClaim;
    }
}
