// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.13;

import "./IAaveDistributionManager.sol";
import "./DistributionTypes.sol";

/**
 * @title DistributionManager
 * @notice Accounting contract to manage multiple staking distributions
 * @author Aave
 */
contract DistributionManager is IAaveDistributionManager {
    struct AssetData {
        uint104 emissionPerSecond;
        uint104 index;
        uint40 lastUpdateTimestamp;
        mapping(address => uint256) users;
    }

    address public immutable EMISSION_MANAGER; // solhint-disable-line var-name-mixedcase

    uint8 public constant PRECISION = 18;
    uint256 public constant TEN_POW_PRECISION = 10 ** PRECISION;

    mapping(address => AssetData) public assets;

    uint256 internal _distributionEnd;

    error OnlyEmissionManager();
    error IndexOverflow();

    modifier onlyEmissionManager() {
        if (msg.sender != EMISSION_MANAGER) revert OnlyEmissionManager();

        _;
    }

    constructor(address emissionManager) {
        EMISSION_MANAGER = emissionManager;
    }

    /// @inheritdoc IAaveDistributionManager
    function setDistributionEnd(uint256 distributionEnd) external override onlyEmissionManager {
        _distributionEnd = distributionEnd;
        emit DistributionEndUpdated(distributionEnd);
    }

    /// @inheritdoc IAaveDistributionManager
    function getDistributionEnd() external view override returns (uint256) {
        return _distributionEnd;
    }

    /// @inheritdoc IAaveDistributionManager
    function DISTRIBUTION_END() external view override returns (uint256) { // solhint-disable-line func-name-mixedcase
        return _distributionEnd;
    }

    /// @inheritdoc IAaveDistributionManager
    function getUserAssetData(address user, address asset) public view override returns (uint256) {
        return assets[asset].users[user];
    }

    /// @inheritdoc IAaveDistributionManager
    function getAssetData(address asset) public view override returns (uint256, uint256, uint256) {
        return (assets[asset].index, assets[asset].emissionPerSecond, assets[asset].lastUpdateTimestamp);
    }

    /**
     * @dev Configure the assets for a specific emission
     * @param assetsConfigInput The array of each asset configuration
     */
    function _configureAssets(DistributionTypes.AssetConfigInput[] memory assetsConfigInput) internal {
        for (uint256 i = 0; i < assetsConfigInput.length;) {
            AssetData storage assetConfig = assets[assetsConfigInput[i].underlyingAsset];

            _updateAssetStateInternal(
                assetsConfigInput[i].underlyingAsset,
                assetConfig,
                assetsConfigInput[i].totalStaked
            );

            assetConfig.emissionPerSecond = assetsConfigInput[i].emissionPerSecond;

            emit AssetConfigUpdated(
                assetsConfigInput[i].underlyingAsset,
                assetsConfigInput[i].emissionPerSecond
            );

            unchecked { i++; }
        }
    }

    /**
     * @dev Updates the state of one distribution, mainly rewards index and timestamp
     * @param asset The address of the asset being updated
     * @param assetConfig Storage pointer to the distribution's config
     * @param totalStaked Current total of staked assets for this distribution
     * @return The new distribution index
     */
    function _updateAssetStateInternal(
        address asset,
        AssetData storage assetConfig,
        uint256 totalStaked
    ) internal returns (uint256) {
        // this method is first called on config, and then when users claims
        // on config: oldIndex is 0
        // on claim `oldIndex` will be some positive index created on config
        uint256 oldIndex = assetConfig.index;
        // on config: some positive value we set as emission
        uint256 emissionPerSecond = assetConfig.emissionPerSecond;
        // on config: 0
        // on claim: it will be time of config setup
        uint128 lastUpdateTimestamp = assetConfig.lastUpdateTimestamp;

        // on config: it is not equal
        // on claim: is not equal (if this is first try of claim)
        if (block.timestamp == lastUpdateTimestamp) {
            return oldIndex;
        }

        // on config _getAssetIndex(0, emissionPerSecond, 0, totalStaked)
        // on config: newIndex will have some positive value
        uint256 newIndex = _getAssetIndex(oldIndex, emissionPerSecond, lastUpdateTimestamp, totalStaked);

        // on config ( positive != 0) => yes
        if (newIndex != oldIndex) {
            if (uint104(newIndex) != newIndex) revert IndexOverflow();

            //optimization: storing one after another saves one SSTORE
            assetConfig.index = uint104(newIndex);
            assetConfig.lastUpdateTimestamp = uint40(block.timestamp);
            emit AssetIndexUpdated(asset, newIndex);
        } else {
            assetConfig.lastUpdateTimestamp = uint40(block.timestamp);
        }

        return newIndex;
    }

    /**
     * @dev Updates the state of an user in a distribution
     * @param user The user's address
     * @param asset The address of the reference asset of the distribution
     * @param stakedByUser Amount of tokens staked by the user in the distribution at the moment
     * @param totalStaked Total tokens staked in the distribution
     * @return The accrued rewards for the user until the moment
     */
    function _updateUserAssetInternal(
        address user,
        address asset,
        uint256 stakedByUser, // ON MINT THIS WILL BE 0
        uint256 totalStaked
    ) internal returns (uint256) {
        AssetData storage assetData = assets[asset];
        // on claim: userIndex is 0 because this is first claim of the user
        uint256 userIndex = assetData.users[user];
        uint256 accruedRewards = 0;

        uint256 newIndex = _updateAssetStateInternal(asset, assetData, totalStaked);

        if (userIndex != newIndex) {
            if (stakedByUser != 0) {
                // ON MINT we will not assign any rewards because stakedByUser == 0
                // however if notification was not done, then on claim stakedByUser != 0 and we enter this place in code
                // and we apply rewards for user who JUST stake
                accruedRewards = _getRewards(stakedByUser, newIndex, userIndex);
            }

            // ON MINT: we save users "starting point"
            assetData.users[user] = newIndex;
            emit UserIndexUpdated(user, asset, newIndex);
        }

        return accruedRewards;
    }

    /**
     * @dev Used by "frontend" stake contracts to update the data of an user when claiming rewards from there
     * @param user The address of the user
     * @param stakes List of structs of the user data related with his stake
     * @return The accrued rewards for the user until the moment
     */
    function _claimRewards(address user, DistributionTypes.UserStakeInput[] memory stakes)
        internal
        returns (uint256)
    {
        uint256 accruedRewards = 0;

        // on claim: here we looping over builded user states for eac hasset
        for (uint256 i = 0; i < stakes.length;) {
            accruedRewards = accruedRewards + _updateUserAssetInternal(
                    user,
                    stakes[i].underlyingAsset,
                    stakes[i].stakedByUser,
                    stakes[i].totalStaked
                );

            unchecked { i++; }
        }

        return accruedRewards;
    }

    /**
     * @dev Return the accrued rewards for an user over a list of distribution
     * @param user The address of the user
     * @param stakes List of structs of the user data related with his stake
     * @return The accrued rewards for the user until the moment
     */
    function _getUnclaimedRewards(address user, DistributionTypes.UserStakeInput[] memory stakes)
        internal
        view
        returns (uint256)
    {
        uint256 accruedRewards = 0;

        for (uint256 i = 0; i < stakes.length;) {
            AssetData storage assetConfig = assets[stakes[i].underlyingAsset];

            uint256 assetIndex = _getAssetIndex(
                assetConfig.index,
                assetConfig.emissionPerSecond,
                assetConfig.lastUpdateTimestamp,
                stakes[i].totalStaked
            );

            accruedRewards = accruedRewards + _getRewards(stakes[i].stakedByUser, assetIndex, assetConfig.users[user]);

            unchecked { i++; }
        }

        return accruedRewards;
    }

    /**
     * @dev Internal function for the calculation of user's rewards on a distribution
     * @param principalUserBalance Amount staked by the user on a distribution
     * @param reserveIndex Current index of the distribution
     * @param userIndex Index stored for the user, representation his staking moment
     * @return rewards The rewards
     */
    function _getRewards(
        uint256 principalUserBalance,
        uint256 reserveIndex,
        uint256 userIndex
    ) internal pure returns (uint256 rewards) {
        rewards = principalUserBalance * (reserveIndex - userIndex);
        unchecked { rewards /= TEN_POW_PRECISION; }
    }

    /**
     * @dev Calculates the next value of an specific distribution index, with validations
     * @param currentIndex Current index of the distribution
     * @param emissionPerSecond Representing the total rewards distributed per second per asset unit,
     * on the distribution
     * @param lastUpdateTimestamp Last moment this distribution was updated
     * @param totalBalance of tokens considered for the distribution
     * @return newIndex The new index.
     */
    function _getAssetIndex(
        uint256 currentIndex,
        uint256 emissionPerSecond,
        uint128 lastUpdateTimestamp,
        uint256 totalBalance
    ) internal view returns (uint256 newIndex) {
        uint256 distributionEnd = _distributionEnd;

        // on config: we not entering this if
        if (
            emissionPerSecond == 0 ||
            totalBalance == 0 ||
            lastUpdateTimestamp == block.timestamp ||
            lastUpdateTimestamp >= distributionEnd
        ) {
            return currentIndex;
        }

        // on config: currentTimestamp = block.timestamp
        uint256 currentTimestamp = block.timestamp > distributionEnd ? distributionEnd : block.timestamp;
        // on config: this will be positive value
        // on claim: timeDelta will be positive, it is time since config setup
        uint256 timeDelta = currentTimestamp - lastUpdateTimestamp;

        // on config: some start index is created that is not zero
        // on claim: emissionPerSecond is the same, TEN_POW_PRECISION is the same, timeDelta is some positive number
        newIndex = emissionPerSecond * timeDelta * TEN_POW_PRECISION;
        // on config: totalBalance is pulled from token
        // NOTE: when user deposit, then we mint share token and totalBalance is increased
        // BUT without notification this contract is not updated with this information
        //
        unchecked { newIndex /= totalBalance; }
        newIndex += currentIndex;
    }
}
