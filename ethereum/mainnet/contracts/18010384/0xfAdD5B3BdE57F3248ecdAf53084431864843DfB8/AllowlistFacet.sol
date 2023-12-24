// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import "./MintOperatorModifiers.sol";
import "./OwnableInternal.sol";
import "./AllowlistStorage.sol";
import "./TransferRestrictionsInternal.sol";

contract AllowlistFacet is MintOperatorModifiers, OwnableInternal, TransferRestrictionsInternal {
    event AllowlistEnabled(bool enabled);

    function allowlistEnabled() external view returns (bool) {
        return AllowlistStorage.layout().isAllowlistEnabled;
    }

    function isOnAllowlist(address account) external view returns (bool) {
        return AllowlistStorage.layout().allowlist[account];
    }

    function setAllowlistEnabled(bool enabled) external onlyOwner {
        AllowlistStorage.layout().isAllowlistEnabled = enabled;
        emit AllowlistEnabled(enabled);
    }

    function bulkAddToAllowlist(address[] calldata accounts) external onlyOwnerOrMintOperator {
        AllowlistStorage.Layout storage l = AllowlistStorage.layout();
        for (uint256 i = 0; i < accounts.length; ) {
            l.allowlist[accounts[i]] = true;

            unchecked {
                i++;
            }
        }
    }

    function bulkRemoveFromAllowlist(address[] calldata accounts) external onlyOwnerOrMintOperator {
        AllowlistStorage.Layout storage l = AllowlistStorage.layout();
        for (uint256 i = 0; i < accounts.length; ) {
            l.allowlist[accounts[i]] = false;

            unchecked {
                i++;
            }
        }
    }

    function setTransferRestrictionDuration(uint248 duration) external onlyOwner {
        AllowlistStorage.layout().transferRestrictionDuration = duration;
    }

    function removeTransferRestriction() external onlyOwner {
        AllowlistStorage.layout().transferRestrictionDuration = 0;
    }

    function getTransferRestrictionDuration() external view returns (uint256) {
        return AllowlistStorage.layout().transferRestrictionDuration;
    }

    function allowlistMintTimestamp(uint256 tokenId) external view returns (uint256) {
        return AllowlistStorage.layout().allowlistMintTimestamps[tokenId];
    }

    function isTokenTransferRestricted(uint256 tokenId) external view returns (bool) {
        return _isTokenTransferRestricted(tokenId);
    }
}
