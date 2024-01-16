// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./IERC1155.sol";

import "./TheTransferManager.sol";

//  1155 transfer
contract TransferManagerERC1155 is TheTransferManager {
    address public immutable UNEMETA_MARKET;

    //  initializing with unemeta trading contract
    constructor(address _unemetaMarket) {
        UNEMETA_MARKET = _unemetaMarket;
    }

    //
    // tion transferNonFungibleToken
    //  @Description: transfer nft
    //  @param address contract address
    //  @param address sender address
    //  @param address  receipient address
    //  @param uint256  tokenId
    //  @param uint256  amount
    //  @return external
    //
    function transferNonFungibleToken(
        address collection,
        address from,
        address to,
        uint256 tokenId,
        uint256 amount
    ) external override {
        require(msg.sender == UNEMETA_MARKET, "Only Unemeta Market can call this function");
        // https://docs.openzeppelin.com/contracts/3.x/api/token/erc1155#IERC1155-safeTransferFrom-address-address-uint256-uint256-bytes-
        IERC1155(collection).safeTransferFrom(from, to, tokenId, amount, "");
    }
}
