// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import "./AllowlistStorage.sol";

contract TransferRestrictionsInternal {
    /**
     * @notice Thrown if the user is trying to transfer a token that is still under the transfer restriction
     */
    error TransferRestricted(uint256 tokenId);

    function _maybeStoreAllowlistMintTimestamp(uint256 tokenId) internal {
        AllowlistStorage.Layout storage al = AllowlistStorage.layout();
        if (al.isAllowlistEnabled) {
            al.allowlistMintTimestamps[tokenId] = uint256(block.timestamp);
        }
    }

    function _enforceAllowlistTransferRestriction(uint256 tokenId) internal view {
        bool shouldRestrict = _isTokenTransferRestricted(tokenId);

        if (shouldRestrict) {
            revert TransferRestricted(tokenId);
        }
    }

    function _isTokenTransferRestricted(uint256 tokenId) internal view returns (bool) {
        AllowlistStorage.Layout storage l = AllowlistStorage.layout();

        uint256 mintTimestamp = l.allowlistMintTimestamps[tokenId];
        if (mintTimestamp == 0) return false;

        return block.timestamp < mintTimestamp + l.transferRestrictionDuration;
    }
}
