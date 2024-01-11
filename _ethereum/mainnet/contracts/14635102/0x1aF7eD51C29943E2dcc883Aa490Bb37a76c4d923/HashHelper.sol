// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

library HashHelper {
    // keccak256("SingleItemAuction(address tokenAddress,uint256 tokenId,uint256 amount,uint256 listOn,uint256 startingPrice,address priceCalculator,address seller)")
    bytes32 internal constant SINGLE_ITEM_AUCTION_HASH = 0x690efce55f6873cc2cf4903c21f626dea40a056811d11e48e991e5e2c7b2e1f4;

    // keccak256("BundleAuction(address tokenAddress,uint256[] tokenIds,uint256[] amounts,uint256 listOn,uint256 startingPrice,address priceCalculator,address seller)")
    bytes32 internal constant BUNDLE_AUCTION_HASH = 0x4a8431ddb4840ad14978d81bf98f5b14f5bc0f9306fab2c4c72c2e01593ad2db;

    function singleAuctionHash(
        address tokenAddress,
        uint256 tokenId,
        uint256 amount,
        uint256 listOn,
        uint256 startingPrice,
        address priceCalculator,
        address seller,
        bytes32 domain) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    domain,
                    SINGLE_ITEM_AUCTION_HASH,
                    tokenAddress,
                    tokenId,
                    amount,
                    listOn,
                    startingPrice,
                    priceCalculator,
                    seller
                )
            );
    }

    function bundleAuctionHash(
        address tokenAddress,
        uint256[] memory tokenIds,
        uint256[] memory amounts,
        uint256 listOn,
        uint256 startingPrice,
        address priceCalculator,
        address seller,
        bytes32 domain) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    domain,
                    BUNDLE_AUCTION_HASH,
                    tokenAddress,
                    tokenIds,
                    amounts,
                    listOn,
                    startingPrice,
                    priceCalculator,
                    seller
                )
            );
    }
}