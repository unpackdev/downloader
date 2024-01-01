// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract DistributionManager {
    struct AssetData {
        uint128 emissionPerSecond;
        uint128 lastUpdateTimestamp;
        uint256 index;
        mapping(address => uint256) users;
    }

    struct AssetConfigInput {
        uint128 emissionPerSecond;
        uint256 totalStaked;
    }

    struct UserStakeInput {
        uint256 stakedByUser;
        uint256 totalStaked;
    }

    /*
    ╔══════════════════════════════╗
    
    ║           VARIABLES          ║
    
    ╚══════════════════════════════╝
    */

    uint256 public distributionEnd;

    uint8 public constant PRECISION = 18;

    AssetData public assetData;

    /*
    ╔══════════════════════════════╗
    
    ║            EVENTS            ║
    
    ╚══════════════════════════════╝
    */

    event AssetConfigUpdated(uint128 emission);
    event AssetIndexUpdated(uint256 index);
    event UserIndexUpdated(address indexed user, uint256 index);

    /*
    ╔══════════════════════════════╗
    
    ║       EXTERNAL FUNCTIONS     ║
    
    ╚══════════════════════════════╝
    */

    /**
     * @param _user Address of the user
     * @return The user index
     **/
    function getUserAssetData(address _user) external view returns (uint256) {
        return assetData.users[_user];
    }

    /*
    ╔══════════════════════════════╗
    
    ║       INTERNAL FUNCTIONS     ║
    
    ╚══════════════════════════════╝
  */

    /**
     * @dev Configures the distribution of rewards for a asset
     * @param _assetConfigInput The configurations to apply
     **/
    function _configureAsset(
        AssetConfigInput memory _assetConfigInput
    ) internal {
        _updateAssetStateInternal(assetData, _assetConfigInput.totalStaked);

        assetData.emissionPerSecond = _assetConfigInput.emissionPerSecond;

        emit AssetConfigUpdated(_assetConfigInput.emissionPerSecond);
    }

    /**
     * @dev Updates the state of distribution, mainly rewards index and timestamp
     * @param _assetConfig Storage pointer to the distribution's config
     * @param _totalStaked Current total of staked asset for a distribution
     * @return The new distribution index
     **/
    function _updateAssetStateInternal(
        AssetData storage _assetConfig,
        uint256 _totalStaked
    ) internal returns (uint256) {
        uint256 oldIndex = _assetConfig.index;
        uint128 lastUpdateTimestamp = _assetConfig.lastUpdateTimestamp;

        if (block.timestamp == lastUpdateTimestamp) {
            return oldIndex;
        }

        uint256 newIndex = _getAssetIndex(
            oldIndex,
            _assetConfig.emissionPerSecond,
            lastUpdateTimestamp,
            _totalStaked
        );

        if (newIndex != oldIndex) {
            _assetConfig.index = newIndex;
            emit AssetIndexUpdated(newIndex);
        }

        _assetConfig.lastUpdateTimestamp = uint128(block.timestamp);

        return newIndex;
    }

    /**
     * @dev Updates the state of an user in a distribution
     * @param _user The user's address
     * @param _stakedByUser Amount of tokens staked by the user in the distribution at the moment
     * @param _totalStaked Total tokens staked in the distribution
     * @return The accrued rewards for the user until the moment
     **/
    function _updateUserAssetInternal(
        address _user,
        uint256 _stakedByUser,
        uint256 _totalStaked
    ) internal returns (uint256) {
        uint256 userIndex = assetData.users[_user];
        uint256 accruedRewards = 0;

        uint256 newIndex = _updateAssetStateInternal(assetData, _totalStaked);

        if (userIndex != newIndex) {
            if (_stakedByUser != 0) {
                accruedRewards = _getRewards(
                    _stakedByUser,
                    newIndex,
                    userIndex
                );
            }

            assetData.users[_user] = newIndex;
            emit UserIndexUpdated(_user, newIndex);
        }

        return accruedRewards;
    }

    /**
     * @dev Used by "frontend" stake contracts to update the data of an user when claiming rewards from there
     * @param _user The address of the user
     * @param _stakes Struct of the user data
     * @return The accrued rewards for the user until the moment
     **/
    function _claimRewards(
        address _user,
        UserStakeInput memory _stakes
    ) internal returns (uint256) {
        uint256 accruedRewards = 0;

        accruedRewards =
            accruedRewards +
            _updateUserAssetInternal(
                _user,
                _stakes.stakedByUser,
                _stakes.totalStaked
            );

        return accruedRewards;
    }

    /**
     * @dev Return the accrued rewards for an user
     * @param _user The address of the user
     * @param _stakes Struct of the user data
     * @return The accrued rewards for the user until the moment
     **/
    function _getUnclaimedRewards(
        address _user,
        UserStakeInput memory _stakes
    ) internal view returns (uint256) {
        uint256 accruedRewards = 0;

        AssetData storage assetConfig = assetData;

        uint256 assetIndex = _getAssetIndex(
            assetConfig.index,
            assetConfig.emissionPerSecond,
            assetConfig.lastUpdateTimestamp,
            _stakes.totalStaked
        );

        accruedRewards =
            accruedRewards +
            _getRewards(
                _stakes.stakedByUser,
                assetIndex,
                assetConfig.users[_user]
            );

        return accruedRewards;
    }

    /**
     * @dev Internal function for the calculation of user's rewards on a distribution
     * @param _principalUserBalance Amount staked by the user on a distribution
     * @param _reserveIndex Current index of the distribution
     * @param _userIndex Index stored for the user, representation his staking moment
     * @return The rewards
     **/
    function _getRewards(
        uint256 _principalUserBalance,
        uint256 _reserveIndex,
        uint256 _userIndex
    ) internal pure returns (uint256) {
        return
            (_principalUserBalance * (_reserveIndex - _userIndex)) /
            (10 ** uint256(PRECISION));
    }

    /**
     * @dev Calculates the next value of an specific distribution index, with validations
     * @param currentIndex Current index of the distribution
     * @param emissionPerSecond Representing the total rewards distributed per second per asset unit, on the distribution
     * @param lastUpdateTimestamp Last moment this distribution was updated
     * @param totalBalance of tokens considered for the distribution
     * @return The new index.
     **/
    function _getAssetIndex(
        uint256 currentIndex,
        uint256 emissionPerSecond,
        uint256 lastUpdateTimestamp,
        uint256 totalBalance
    ) internal view returns (uint256) {
        if (
            emissionPerSecond == 0 ||
            totalBalance == 0 ||
            lastUpdateTimestamp == block.timestamp ||
            lastUpdateTimestamp >= distributionEnd
        ) {
            return currentIndex;
        }

        uint256 currentTimestamp = block.timestamp > distributionEnd
            ? distributionEnd
            : block.timestamp;
        uint256 timeDelta = currentTimestamp - lastUpdateTimestamp;
        return
            (emissionPerSecond * (timeDelta) * (10 ** uint256(PRECISION))) /
            (totalBalance) +
            (currentIndex);
    }
}
