// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import "./OwnableInternal.sol";
import "./DiamondBaseStorage.sol";
import "./IDiamondWritable.sol";
import "./DiamondWritableInternal.sol";

/**
 * @title EIP-2535 "Diamond" proxy update contract
 */
abstract contract DiamondWritable is
    IDiamondWritable,
    DiamondWritableInternal,
    OwnableInternal
{
    using DiamondBaseStorage for DiamondBaseStorage.Layout;

    /**
     * @inheritdoc IDiamondWritable
     */
    function diamondCut(
        FacetCut[] calldata facetCuts,
        address target,
        bytes calldata data
    ) external onlyOwner {
        _diamondCut(facetCuts, target, data);
    }
}
