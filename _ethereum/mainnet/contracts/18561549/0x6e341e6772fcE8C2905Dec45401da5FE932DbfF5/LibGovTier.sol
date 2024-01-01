// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./IERC20.sol";
import "./LibGovTierStorage.sol";
import "./LibAppStorage.sol";

library LibGovTier {
    event TierLevelAdded(
        bytes32 _newTierLevel,
        LibGovTierStorage.TierData _tierData
    );
    event TierLevelUpdated(
        bytes32 _updatetierLevel,
        LibGovTierStorage.TierData _tierData
    );
    event TierLevelRemoved(bytes32 _removedtierLevel);
    event AddedWalletTier(address _userAddress, bytes32 _tierLevel);
    event UpdatedWalletTier(address _wallet, bytes32 _tierLevel);

    /// @dev update already created tier level
    /// @param _updatedTierLevelKey key value type of the already created Tier Level in bytes
    /// @param _newTierData access variables for updating the Tier Level

    function _updateTierLevel(
        bytes32 _updatedTierLevelKey,
        LibGovTierStorage.TierData memory _newTierData
    ) internal {
        LibGovTierStorage.GovTierStorage storage es = LibGovTierStorage
            .govTierStorage();
        //update Tier Level to the updatedTier
        uint256 currentIndex = _getIndex(_updatedTierLevelKey);
        uint256 lowerLimit = 0;
        uint256 upperLimit = _newTierData.govHoldings + 10;
        if (currentIndex > 0) {
            lowerLimit = es
                .tierLevels[es.allTierLevelKeys[currentIndex - 1]]
                .govHoldings;
        }
        if (currentIndex < es.allTierLevelKeys.length - 1)
            upperLimit = es
                .tierLevels[es.allTierLevelKeys[currentIndex + 1]]
                .govHoldings;

        require(
            _newTierData.govHoldings < upperLimit &&
                _newTierData.govHoldings > lowerLimit,
            "GTL: Holdings Range Error"
        );

        es.tierLevels[_updatedTierLevelKey] = _newTierData;
        emit TierLevelUpdated(_updatedTierLevelKey, _newTierData);
    }

    /// @dev remove tier level
    /// @param index already existing tierlevel index

    function _removeTierLevelKey(uint256 index) internal {
        LibGovTierStorage.GovTierStorage storage es = LibGovTierStorage
            .govTierStorage();

        uint256 length = es.allTierLevelKeys.length;

        // Swap the element to remove with the last element
        uint256 lastIndex = length - 1;
        if (index != lastIndex) {
            es.allTierLevelKeys[index] = es.allTierLevelKeys[lastIndex];
        }

        es.allTierLevelKeys.pop();
    }

    /// @dev internal function for the save tier level, which will update and add tier level in the same tx

    function _saveTierLevel(
        bytes32[] memory _tierLevelKeys,
        LibGovTierStorage.TierData[] memory _newTierData
    ) internal {
        LibGovTierStorage.GovTierStorage storage es = LibGovTierStorage
            .govTierStorage();
        for (uint256 i = 0; i < _tierLevelKeys.length; i++) {
            if (!LibGovTier.isAlreadyTierLevel(_tierLevelKeys[i])) {
                require(
                    _newTierData[i].govHoldings >
                        es
                            .tierLevels[
                                es.allTierLevelKeys[maxGovTierLevelIndex()]
                            ]
                            .govHoldings,
                    "GovHolding Should be greater then last tier level Gov Holdings"
                );
                LibGovTier._addTierLevel(_tierLevelKeys[i], _newTierData[i]);
            } else if (LibGovTier.isAlreadyTierLevel(_tierLevelKeys[i])) {
                LibGovTier._updateTierLevel(_tierLevelKeys[i], _newTierData[i]);
            }
        }
    }

    /// @dev get index of the tierLevel from the allTierLevel array
    /// @param _tierLevel hash of the tier level

    function _getIndex(
        bytes32 _tierLevel
    ) internal view returns (uint256 index) {
        LibGovTierStorage.GovTierStorage storage es = LibGovTierStorage
            .govTierStorage();
        uint256 length = es.allTierLevelKeys.length;
        for (uint256 i = 0; i < length; i++) {
            if (es.allTierLevelKeys[i] == _tierLevel) {
                return i;
            }
        }
    }

    /// @dev makes _new a pendsing adnmin for approval to be given by all current admins
    /// @param _newTierLevel value type of the New Tier Level in bytes
    /// @param _tierData access variables for _newadmin

    function _addTierLevel(
        bytes32 _newTierLevel,
        LibGovTierStorage.TierData memory _tierData
    ) internal {
        LibGovTierStorage.GovTierStorage storage es = LibGovTierStorage
            .govTierStorage();
        AppStorage storage s = LibAppStorage.appStorage();

        require(
            es.allTierLevelKeys.length + 1 <= LibAppStorage.arrayMaxSize,
            "GTL: array size exceed"
        );

        require(
            _tierData.govHoldings < IERC20(s.govToken).totalSupply(),
            "GTL: tier holding exceed gov token total supply"
        );
        require(
            !LibGovTier.isAlreadyTierLevel(_newTierLevel),
            "GTL: already added tier level"
        );
        //new Tier is added to the mapping tierLevels
        es.tierLevels[_newTierLevel] = _tierData;

        //new Tier Key for mapping tierLevel
        es.allTierLevelKeys.push(_newTierLevel);
        emit TierLevelAdded(_newTierLevel, _tierData);
    }

    /// @dev Checks if a given _newTierLevel is already added by the admin.
    /// @param _tierLevel value of the new tier

    function isAlreadyTierLevel(
        bytes32 _tierLevel
    ) internal view returns (bool) {
        LibGovTierStorage.GovTierStorage storage es = LibGovTierStorage
            .govTierStorage();
        uint256 length = es.allTierLevelKeys.length;
        for (uint256 i = 0; i < length; i++) {
            if (es.allTierLevelKeys[i] == _tierLevel) {
                return true;
            }
        }
        return false;
    }

    /// @dev this function returns the index of the maximum govholding tier level

    function maxGovTierLevelIndex() internal view returns (uint256) {
        LibGovTierStorage.GovTierStorage storage es = LibGovTierStorage
            .govTierStorage();
        uint256 max = es.tierLevels[es.allTierLevelKeys[0]].govHoldings;
        uint256 maxIndex = 0;

        uint256 length = es.allTierLevelKeys.length;
        for (uint256 i = 0; i < length; i++) {
            if (es.tierLevels[es.allTierLevelKeys[i]].govHoldings > max) {
                maxIndex = i;
                max = es.tierLevels[es.allTierLevelKeys[i]].govHoldings;
            }
        }

        return maxIndex;
    }
}
