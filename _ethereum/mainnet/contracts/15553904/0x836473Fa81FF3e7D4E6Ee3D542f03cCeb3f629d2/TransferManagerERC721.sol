// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./IERC721.sol";

import "./TheTransferManager.sol";

/**
 * @title TransferManagerERC721
 * @notice It allows the transfer of ERC721 tokens.
 */
contract TransferManagerERC721 is TheTransferManager {
    address public immutable UNEMETA_MARKET;

    /**
     * @notice Constructor
     * @param _unemetaMarket address of the Unemeta exchange
     */
    constructor(address _unemetaMarket) {
        UNEMETA_MARKET = _unemetaMarket;
    }

    //
    // function transferNonFungibleToken
    //  @Description: transfer nft
    //  @param address
    //  @param address
    //  @param address
    //  @param uint256
    //  @param uint256
    //  @return external
    //
    function transferNonFungibleToken(
        address collection,
        address from,
        address to,
        uint256 tokenId,
        uint256
    ) external override {
        require(msg.sender == UNEMETA_MARKET, "Only Unemeta Market can call this function");
        // https://docs.openzeppelin.com/contracts/2.x/api/token/erc721#IERC721-safeTransferFrom
        IERC721(collection).safeTransferFrom(from, to, tokenId);
    }
}
