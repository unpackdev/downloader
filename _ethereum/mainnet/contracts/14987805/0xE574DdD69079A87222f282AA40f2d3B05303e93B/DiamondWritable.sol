// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./OwnableInternal.sol";
import "./DiamondBaseStorage.sol";
import "./IDiamondWritable.sol";

/**
 * @title EIP-2535 "Diamond" proxy update contract
 */
abstract contract DiamondWritable is IDiamondWritable, OwnableInternal {
    using DiamondBaseStorage for DiamondBaseStorage.Layout;

    /**
     * @inheritdoc IDiamondWritable
     */
    function diamondCut(
        FacetCut[] calldata facetCuts,
        address target,
        bytes calldata data
    ) external onlyOwner {
        DiamondBaseStorage.layout().diamondCut(facetCuts, target, data);
    }
}
