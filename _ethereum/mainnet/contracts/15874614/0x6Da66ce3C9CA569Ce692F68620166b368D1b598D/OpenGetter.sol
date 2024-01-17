// SPDX-License-Identifier: MIT
//
//
//       ___           ___         ___           ___              ___           ___                     ___
//      /  /\         /  /\       /  /\         /__/\            /__/\         /  /\        ___        /  /\
//     /  /::\       /  /::\     /  /:/_        \  \:\           \  \:\       /  /:/_      /  /\      /  /:/_
//    /  /:/\:\     /  /:/\:\   /  /:/ /\        \  \:\           \  \:\     /  /:/ /\    /  /:/     /  /:/ /\
//   /  /:/  \:\   /  /:/~/:/  /  /:/ /:/_   _____\__\:\      _____\__\:\   /  /:/ /:/   /  /:/     /  /:/ /::\
//  /__/:/ \__\:\ /__/:/ /:/  /__/:/ /:/ /\ /__/::::::::\    /__/::::::::\ /__/:/ /:/   /  /::\    /__/:/ /:/\:\
//  \  \:\ /  /:/ \  \:\/:/   \  \:\/:/ /:/ \  \:\~~\~~\/    \  \:\~~\~~\/ \  \:\/:/   /__/:/\:\   \  \:\/:/~/:/
//   \  \:\  /:/   \  \::/     \  \::/ /:/   \  \:\  ~~~      \  \:\  ~~~   \  \::/    \__\/  \:\   \  \::/ /:/
//    \  \:\/:/     \  \:\      \  \:\/:/     \  \:\           \  \:\        \  \:\         \  \:\   \__\/ /:/
//     \  \::/       \  \:\      \  \::/       \  \:\           \  \:\        \  \:\         \__\/     /__/:/
//      \__\/         \__\/       \__\/         \__\/            \__\/         \__\/                   \__\/
//
//   OpenChecker
//        |
//  OpenGetter —— IOpenGetter
//
pragma solidity 0.8.9;

import "./OpenChecker.sol";
import "./IOpenGetter.sol";
import "./IERC721.sol";
import "./IERC721Metadata.sol";
import "./IERC721Enumerable.sol";
import "./IERC1155.sol";
import "./IERC1155MetadataURI.sol";
import "./IERC165.sol";
import "./IERC173.sol";

abstract contract OpenGetter is IOpenGetter, OpenChecker {
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override (OpenChecker)
        returns (bool)
    {
        return interfaceId == type(IOpenGetter).interfaceId || super.supportsInterface(interfaceId);
    }

    function getCollectionInfos(address collection, address account)
        public
        view
        override (IOpenGetter)
        returns (
            // override(IOpenGetter)
            CollectionInfos memory collectionInfos
        )
    {
        collectionInfos = _getCollectionInfos(collection, account, new bytes4[](0));
    }

    function getNftsInfos(address collection, uint256[] memory tokenIDs, address account)
        public
        view
        override (IOpenGetter)
        returns (NftInfos[] memory nftsInfos)
    {
        nftsInfos = new NftInfos[](tokenIDs.length);
        for (uint256 i; i < tokenIDs.length; i++) {
            nftsInfos[i] = _getNftInfos(collection, tokenIDs[i], account);
        }
    }

    function getNftsInfos(address collection, address account, uint256 limit, uint256 offset)
        public
        view
        override (IOpenGetter)
        returns (NftInfos[] memory nftsInfos, uint256 count, uint256 total)
    {
        bool[] memory supported = checkErcInterfaces(collection);

        // IF ERC721 & ERC721Enumerable supported
        if (supported[2] && supported[4]) {
            if (account == address(0)) {
                total = IERC721Enumerable(collection).totalSupply();

                require(offset <= total, "Invalid offset");
                count = (offset + limit <= total) ? limit : total - offset;

                nftsInfos = new NftInfos[](count);
                for (uint256 i; i < count; i++) {
                    nftsInfos[i] = _getNftInfos(
                        collection, IERC721Enumerable(collection).tokenByIndex(offset + i), account
                    );
                }
            } else {
                total = IERC721(collection).balanceOf(account);

                require(offset <= total, "Invalid offset");
                count = (offset + limit <= total) ? limit : total - offset;

                nftsInfos = new NftInfos[](count);
                for (uint256 i; i < count; i++) {
                    nftsInfos[i] = _getNftInfos(
                        collection,
                        IERC721Enumerable(collection).tokenOfOwnerByIndex(account, offset + i),
                        account
                    );
                }
            }
        }
    }

    function getNftInfos(address collection, uint256 tokenID, address account)
        public
        view
        override (IOpenGetter)
        returns (NftInfos memory nftInfos)
    {
        return _getNftInfos(collection, tokenID, account);
    }

    function _getNftInfos(address collection, uint256 tokenID, address account)
        internal
        view
        onlyContract(collection)
        returns (NftInfos memory nftInfos)
    {
        nftInfos.tokenID = tokenID;
        nftInfos.approved = IERC721(collection).getApproved(tokenID);
        nftInfos.owner = IERC721(collection).ownerOf(tokenID);

        if (IERC165(collection).supportsInterface(0x5b5e139f)) {
            // ERC721Metadata
            nftInfos.tokenURI = IERC721Metadata(collection).tokenURI(tokenID);
        } else if (IERC165(collection).supportsInterface(0x0e89341c)) {
            // ERC1155MetadataURI
            nftInfos.tokenURI = IERC1155MetadataURI(collection).uri(tokenID);
            nftInfos.balanceOf = IERC1155(collection).balanceOf(account, tokenID);
        }
    }

    function _getCollectionInfos(address collection, address account, bytes4[] memory interfaceIds)
        internal
        view
        onlyContract(collection)
        returns (CollectionInfos memory collectionInfos)
    {
        bool[] memory supported = checkSupportedInterfaces(collection, true, interfaceIds);
        collectionInfos.supported = supported;

        // ERC165 must be supported
        require(!supported[0] && supported[1], "Not ERC165");

        // ERC721 or ERC1155 must be supported
        require(supported[2] || supported[6], "Not NFT smartcontract");

        collectionInfos.collection = collection;

        // try ERC173 owner
        try IERC173(collection).owner() returns (address owner) {
            collectionInfos.owner = owner;
        } catch {}

        // try ERC721Metadata name
        try IERC721Metadata(collection).name() returns (string memory name) {
            collectionInfos.name = name;
        } catch {}

        // try ERC721Metadata symbol
        try IERC721Metadata(collection).symbol() returns (string memory symbol) {
            collectionInfos.symbol = symbol;
        } catch {}

        // try ERC721Enumerable totalSupply
        try IERC721Enumerable(collection).totalSupply() returns (uint256 totalSupply) {
            collectionInfos.totalSupply = totalSupply;
        } catch {}

        if (account != address(0)) {
            try IERC721(collection).balanceOf(account) returns (uint256 balanceOf) {
                collectionInfos.balanceOf = balanceOf;
            } catch {}

            try IERC721(collection).isApprovedForAll(account, collection) returns (
                bool approvedForAll
            ) {
                collectionInfos.approvedForAll = approvedForAll;
            } catch {}
        }
    }
}
