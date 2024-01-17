// SPDX-License-Identifier: MIT
//
//    OpenERC165
//        |
//  OpenResolver
//        |
//  OpenNFTsResolver —— IOpenNFTsResolver
//
pragma solidity 0.8.9;

import "./OpenResolver.sol";
import "./IOpenNFTsResolver.sol";
import "./IAll.sol";

contract OpenNFTsResolver is IOpenNFTsResolver, OpenResolver {
    bytes4[] private _interfaceIds = new bytes4[](12);

    uint8 private constant _IERC_2981 = 10;
    uint8 private constant _IERC_LENGTH = 11;

    uint8 private constant _IOPEN_NFTS = _IERC_LENGTH + 0;
    uint8 private constant _IOPEN_CHECKER = _IERC_LENGTH + 1;
    uint8 private constant _IOPEN_CLONEABLE = _IERC_LENGTH + 2;
    uint8 private constant _IOPEN_MARKETABLE = _IERC_LENGTH + 3;
    uint8 private constant _IOPEN_PAUSEABLE = _IERC_LENGTH + 4;

    uint8 private constant _IOPEN_NFTS_V0 = _IERC_LENGTH + 5;
    uint8 private constant _IOPEN_NFTS_V1 = _IERC_LENGTH + 6;
    uint8 private constant _IOPEN_NFTS_V2 = _IERC_LENGTH + 7;
    uint8 private constant _IOPEN_NFTS_V3 = _IERC_LENGTH + 8;
    uint8 private constant _IOPEN_NFTS_V4 = _IERC_LENGTH + 9;
    uint8 private constant _IOPEN_AUTOMARKET = _IERC_LENGTH + 10;
    uint8 private constant _IOPEN_BOUND = _IERC_LENGTH + 11;

    constructor(address owner_, address registerer_) {
        OpenERC173._initialize(owner_);
        OpenRegistry._setRegisterer(registerer_);

        /// 0xffffffff :  O Invalid
        /// 0x01ffc9a7 :  1 ERC165
        /// 0x80ac58cd :  2 ERC721
        /// 0x5b5e139f :  3 ERC721Metadata
        /// 0x780e9d63 :  4 ERC721Enumerable
        /// 0x150b7a02 :  5 ERC721TokenReceiver
        /// 0xd9b67a26 :  6 ERC1155
        /// 0x0e89341c :  7 ERC1155MetadataURI
        /// 0x4e2312e0 :  8 ERC1155TokenReceiver
        /// 0x7f5828d0 :  9 ERC173
        /// 0x2a55205a : 10 ERC2981

        _interfaceIds[_IOPEN_NFTS - _IERC_LENGTH] = type(IOpenNFTs).interfaceId;
        _interfaceIds[_IOPEN_CHECKER - _IERC_LENGTH] = type(IOpenChecker).interfaceId;
        _interfaceIds[_IOPEN_CLONEABLE - _IERC_LENGTH] = type(IOpenCloneable).interfaceId;
        _interfaceIds[_IOPEN_MARKETABLE - _IERC_LENGTH] = type(IOpenMarketable).interfaceId;
        _interfaceIds[_IOPEN_PAUSEABLE - _IERC_LENGTH] = type(IOpenPauseable).interfaceId;

        _interfaceIds[_IOPEN_NFTS_V0 - _IERC_LENGTH] = type(IOpenNFTsV0).interfaceId;
        _interfaceIds[_IOPEN_NFTS_V1 - _IERC_LENGTH] = type(IOpenNFTsV1).interfaceId;
        _interfaceIds[_IOPEN_NFTS_V2 - _IERC_LENGTH] = type(IOpenNFTsV2).interfaceId;
        _interfaceIds[_IOPEN_NFTS_V3 - _IERC_LENGTH] = type(IOpenNFTsV3).interfaceId;
        _interfaceIds[_IOPEN_NFTS_V4 - _IERC_LENGTH] = type(IOpenNFTsV4).interfaceId;
        _interfaceIds[_IOPEN_AUTOMARKET - _IERC_LENGTH] = type(IOpenAutoMarket).interfaceId;
        _interfaceIds[_IOPEN_BOUND - _IERC_LENGTH] = type(IOpenBound).interfaceId;
    }

    function getOpenNFTsNftsInfos(
        address collection,
        address account,
        uint256 limit,
        uint256 offset
    )
        external
        view
        override(IOpenNFTsResolver)
        returns (
            NftInfos[] memory nftInfos,
            OpenNFTsNftInfos[] memory openNTFsNftInfos,
            CollectionInfos memory collectionInfos,
            uint256 count,
            uint256 total
        )
    {
        collectionInfos = OpenGetter._getCollectionInfos(collection, account, _interfaceIds);

        (nftInfos, count, total) = OpenGetter.getNftsInfos(collection, account, limit, offset);

        openNTFsNftInfos = new OpenNFTsNftInfos[](nftInfos.length);
        for (uint256 i = 0; i < nftInfos.length; i++) {
            openNTFsNftInfos[i] = _getOpenNFTsNftInfos(collection, nftInfos[i].tokenID, collectionInfos.supported);
        }
    }

    function getOpenNFTsNftsInfos(
        address collection,
        uint256[] memory tokenIDs,
        address account
    )
        external
        view
        override(IOpenNFTsResolver)
        returns (
            NftInfos[] memory nftInfos,
            OpenNFTsNftInfos[] memory openNTFsNftInfos,
            CollectionInfos memory collectionInfos
        )
    {
        collectionInfos = OpenGetter._getCollectionInfos(collection, address(0), _interfaceIds);

        nftInfos = OpenGetter.getNftsInfos(collection, tokenIDs, account);
        openNTFsNftInfos = new OpenNFTsNftInfos[](tokenIDs.length);
        for (uint256 i = 0; i < tokenIDs.length; i++) {
            openNTFsNftInfos[i] = _getOpenNFTsNftInfos(collection, tokenIDs[i], collectionInfos.supported);
        }
    }

    function getOpenNFTsNftInfos(
        address collection,
        uint256 tokenID,
        address account
    )
        external
        view
        override(IOpenNFTsResolver)
        returns (
            NftInfos memory nftInfos,
            OpenNFTsNftInfos memory openNTFsNftInfos,
            CollectionInfos memory collectionInfos
        )
    {
        collectionInfos = OpenGetter._getCollectionInfos(collection, account, _interfaceIds);

        nftInfos = OpenGetter.getNftInfos(collection, tokenID, account);
        openNTFsNftInfos = _getOpenNFTsNftInfos(collection, tokenID, collectionInfos.supported);
    }

    function getOpenNFTsCollectionsInfos(address account)
        external
        view
        override(IOpenNFTsResolver)
        returns (
            CollectionInfos[] memory collectionsInfos,
            OpenNFTsCollectionInfos[] memory openNFTsCollectionsInfos,
            uint256 count,
            uint256 total
        )
    {
        CollectionInfos[] memory collectionsInfosAll = getCollectionsInfos(getAddresses(), account, _interfaceIds);
        total = collectionsInfosAll.length;

        for (uint256 i = 0; i < collectionsInfosAll.length; i++) {
            if (collectionsInfosAll[i].balanceOf > 0 || collectionsInfosAll[i].owner == account) {
                count++;
            }
        }

        collectionsInfos = new CollectionInfos[](count);
        openNFTsCollectionsInfos = new OpenNFTsCollectionInfos[](count);

        uint256 j;
        for (uint256 i = 0; i < total; i++) {
            if (collectionsInfosAll[i].balanceOf > 0 || collectionsInfosAll[i].owner == account) {
                collectionsInfos[j] = collectionsInfosAll[i];
                openNFTsCollectionsInfos[j] = _getOpenNFTsCollectionInfos(
                    collectionsInfosAll[i].collection,
                    collectionsInfosAll[i].supported
                );
                j++;
            }
        }
    }

    function getOpenNFTsCollectionInfos(address collection, address account)
        external
        view
        override(IOpenNFTsResolver)
        returns (CollectionInfos memory collectionInfos, OpenNFTsCollectionInfos memory openNTFscollectionInfos)
    {
        collectionInfos = OpenGetter._getCollectionInfos(collection, account, _interfaceIds);
        openNTFscollectionInfos = _getOpenNFTsCollectionInfos(collection, collectionInfos.supported);
    }

    function supportsInterface(bytes4 interfaceId) public view override(OpenResolver) returns (bool) {
        return interfaceId == type(IOpenNFTsResolver).interfaceId || super.supportsInterface(interfaceId);
    }

    function _getOpenNFTsNftInfos(
        address collection,
        uint256 tokenID,
        bool[] memory supported
    ) internal view returns (OpenNFTsNftInfos memory nftInfos) {
        if (supported[_IOPEN_MARKETABLE]) {
            nftInfos.receiver = IOpenMarketable(payable(collection)).getTokenRoyalty(tokenID);
            nftInfos.price = IOpenMarketable(payable(collection)).getTokenPrice(tokenID);
        } else if (supported[_IERC_2981]) {
            (nftInfos.receiver.account, ) = IERC2981(payable(collection)).royaltyInfo(tokenID, 1);
        }
    }

    function _getOpenNFTsCollectionInfos(address collection, bool[] memory supported)
        internal
        view
        returns (OpenNFTsCollectionInfos memory collInfos)
    {
        if (supported[_IOPEN_CLONEABLE]) {
            collInfos.version = IOpenCloneable(collection).version(); // 4
            collInfos.template = IOpenCloneable(collection).template(); // OpenNFTsV4 or OpenBound
            collInfos.open = IOpenNFTsV4(collection).open();
        } else if (supported[_IOPEN_NFTS_V3]) {
            collInfos.version = 3;
            collInfos.template = "OpenNFTsV3";
            collInfos.open = IOpenNFTsV3(collection).open();
        } else if (supported[_IOPEN_NFTS_V2]) {
            collInfos.version = 2;
        } else if (supported[_IOPEN_NFTS_V1]) {
            collInfos.version = 1;
        }

        if (supported[_IOPEN_MARKETABLE]) {
            collInfos.receiver = IOpenMarketable(payable(collection)).getDefaultRoyalty();
            collInfos.price = IOpenMarketable(payable(collection)).getMintPrice();
            collInfos.minimal = IOpenMarketable(payable(collection)).minimal();
        }
    }
}
