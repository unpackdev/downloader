// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./LibGovNFTTierStorage.sol";

library LibGovNFTTier {
    /// @dev remove single sp tieer level key
    /// @param index already existing tierlevel index

    function _removeSingleSpTierLevelKey(uint256 index) internal {
        LibGovNFTTierStorage.GovNFTTierStorage storage es = LibGovNFTTierStorage
            .govNftTierStorage();

        uint256 length = es.spTierLevelKeys.length;

        // Swap the element to remove with the last element
        uint256 lastIndex = length - 1;
        if (index != lastIndex) {
            es.spTierLevelKeys[index] = es.spTierLevelKeys[lastIndex];
        }

        // Delete the last element
        es.spTierLevelKeys.pop();
    }

    function _removeNftTierLevelKey(uint256 index) internal {
        LibGovNFTTierStorage.GovNFTTierStorage storage es = LibGovNFTTierStorage
            .govNftTierStorage();

        uint256 length = es.nftTierLevelsKeys.length;

        // Swap the element to remove with the last element
        uint256 lastIndex = length - 1;
        if (index != lastIndex) {
            es.nftTierLevelsKeys[index] = es.nftTierLevelsKeys[lastIndex];
        }

        // Delete the last element
        es.nftTierLevelsKeys.pop();
    }

    /// @dev get index of the singleSpTierLevel from the allTierLevel array
    /// @param _tier hash of the tier level

    function _getIndexSpTier(
        uint256 _tier
    ) internal view returns (uint256 index) {
        LibGovNFTTierStorage.GovNFTTierStorage storage es = LibGovNFTTierStorage
            .govNftTierStorage();
        uint256 length = es.spTierLevelKeys.length;

        for (uint256 i = 0; i < length; i++) {
            if (es.spTierLevelKeys[i] == _tier) {
                return i;
            }
        }
    }

    /// @dev get index of the nftTierLevel from the allTierLevel array
    /// @param _tier hash of the tier level

    function _getIndexNftTier(
        address _tier
    ) internal view returns (uint256 index) {
        LibGovNFTTierStorage.GovNFTTierStorage storage es = LibGovNFTTierStorage
            .govNftTierStorage();

        uint256 length = es.nftTierLevelsKeys.length;

        for (uint256 i = 0; i < length; i++) {
            if (es.nftTierLevelsKeys[i] == _tier) {
                return i;
            }
        }
    }

    function isAlreadyNftTier(
        address _nftAddress
    ) internal view returns (bool) {
        LibGovNFTTierStorage.GovNFTTierStorage storage es = LibGovNFTTierStorage
            .govNftTierStorage();
        uint256 length = es.nftTierLevelsKeys.length;
        for (uint256 i = 0; i < length; i++) {
            if (es.nftTierLevelsKeys[i] == _nftAddress) {
                return true;
            }
        }
        return false;
    }
}
