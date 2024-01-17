// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./IOpenNFTsInfos.sol";

interface IOpenNFTsResolver is IOpenNFTsInfos {
    function getOpenNFTsNftsInfos(
        address collection,
        address account,
        uint256 limit,
        uint256 offset
    )
        external
        view
        returns (
            NftInfos[] memory nftInfos,
            OpenNFTsNftInfos[] memory openNTFsnftInfos,
            CollectionInfos memory collectionInfos,
            uint256 count,
            uint256 total
        );

    function getOpenNFTsNftsInfos(
        address collection,
        uint256[] memory tokenIDs,
        address account
    )
        external
        view
        returns (
            NftInfos[] memory nftInfos,
            OpenNFTsNftInfos[] memory openNTFsnftInfos,
            CollectionInfos memory collectionInfos
        );

    function getOpenNFTsNftInfos(
        address collection,
        uint256 tokenID,
        address account
    )
        external
        view
        returns (
            NftInfos memory nftInfos,
            OpenNFTsNftInfos memory openNTFsnftInfos,
            CollectionInfos memory collectionInfos
        );

    function getOpenNFTsCollectionsInfos(address account)
        external
        view
        returns (
            CollectionInfos[] memory collectionsInfos,
            OpenNFTsCollectionInfos[] memory openNFTsCollectionsInfos,
            uint256 count,
            uint256 total
        );

    function getOpenNFTsCollectionInfos(address collection, address account)
        external
        view
        returns (CollectionInfos memory collectionInfos, OpenNFTsCollectionInfos memory openNTFscollectionInfos);
}
