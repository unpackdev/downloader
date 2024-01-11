// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./MADTypeDefinitions.sol";

/**
 * @title [Interface] MAD's Radical Market callback hooks
 * @author Neptune
 */
abstract contract IMADRadicalMarketDelegate is MADTypeDefinitions {
    /**
     * @dev Called when asset is no longer being bid in Radical Market
     */
    function didReleaseAsset(Metaverse metaverse, uint256 assetId)
        external
        virtual;

    /**
     * @dev Called when asset has been acquired by a bidder in Radical Market
     * This should only be called when the asset was previous idle and in use by Ads
     */
    function didAcquireLenderForAsset(
        Metaverse metaverse,
        uint256 assetId,
        address lender
    ) external virtual;
}
