// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface BezelClubIERC721 {
     struct LazyMintData {
        address seller;
        address buyer;
        string currency;
        uint256 price;
        string uid;
        bytes signature;
    }

    function lazyMint(LazyMintData calldata _lazyData)
        external returns (uint256 tokenId_);
}
