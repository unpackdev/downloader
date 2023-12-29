// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import "./OwnableInternal.sol";
import "./IDiamondWritable.sol";
import "./DiamondWritableInternal.sol";
import "./DiamondWritableRevokableStorage.sol";

/**
 * @title EIP-2535 "Diamond" proxy update contract with built in revokability
 */
abstract contract DiamondWritableRevokable is IDiamondWritable, DiamondWritableInternal, OwnableInternal {
    error UpgradeabilityRevoked();

    /**
     * @inheritdoc IDiamondWritable
     * @dev also checks to ensure upgradeability has not been revoked
     */
    function diamondCut(FacetCut[] calldata facetCuts, address target, bytes calldata data) external onlyOwner {
        if (DiamondWritableRevokableStorage.layout().isUpgradeabiltyRevoked) revert UpgradeabilityRevoked();
        _diamondCut(facetCuts, target, data);
    }
}
