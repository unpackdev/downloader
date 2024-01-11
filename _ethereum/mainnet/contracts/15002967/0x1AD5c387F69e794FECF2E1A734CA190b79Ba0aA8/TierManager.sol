// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

abstract contract TierManager {
    mapping(uint256 => uint96) _tokenIDToTierID;
    mapping(uint96 => uint256) public maxLimitPerTier;
    mapping(uint96 => uint256) totalTokensPerTier;
    uint96 totalTiers;

    event TierInfo(uint96 tierId, uint256 maxLimit);
    event SetTierForToken(uint256 token, uint96 tierId);

    /// @dev this function takes an array of tier data and stores the royalty informatiåon and max token limit per tier.

    function _addTiersInfo(uint256[] calldata _maxLimitPerTier) internal {
        // require(_fee.length == _maxLimitPerTier.length, "TierManager: tier and fee data must be of the same size");
        for (uint96 i = 0; i < _maxLimitPerTier.length; i++) {
            totalTiers++;
            maxLimitPerTier[totalTiers] = _maxLimitPerTier[i];
            emit TierInfo(totalTiers, _maxLimitPerTier[i]);
        }
    }

    function _updateTierInfoByTierId(uint96 _tierID, uint256 _maxLimitPerTier) internal {
        require(_tierID <= totalTiers, "TierManager: tier id does not exist");
        maxLimitPerTier[_tierID] = _maxLimitPerTier;
        emit TierInfo(_tierID, _maxLimitPerTier);
    }

    /// @dev this function sets the token ID to tier ID
    function _setTierForToken(uint256 _tokenId, uint96 _tierId) internal {
        _tokenIDToTierID[_tokenId] = _tierId;
        emit SetTierForToken(_tokenId, _tierId);
    }

    /// @dev this function gets the tier ID for a token ID
    /// @return the tier ID for a token ID

    function _getTierByToken(uint256 _tokenId) internal view returns (uint96) {
        return _tokenIDToTierID[_tokenId];
    }
}
