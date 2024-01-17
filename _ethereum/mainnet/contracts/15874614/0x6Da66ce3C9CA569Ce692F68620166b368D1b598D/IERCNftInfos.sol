// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

// Infos of either ERC721 or ERC1155 NFT
interface IERCNftInfos {
    enum NftType {
        ERC721,
        ERC1155
    }

    struct CollectionInfos {
        address collection;
        address owner;
        string name;
        string symbol;
        uint256 totalSupply;
        uint256 balanceOf;
        bool approvedForAll;
        bool[] supported;
        NftType erc;
    }

    struct NftInfos {
        uint256 tokenID;
        string tokenURI;
        address owner;
        address approved;
        uint256 balanceOf;
        NftType erc;
    }
}
