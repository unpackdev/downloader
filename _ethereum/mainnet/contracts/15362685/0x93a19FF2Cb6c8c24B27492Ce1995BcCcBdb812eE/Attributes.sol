// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;


struct ExchangeOrder {
    address seller;
    uint256 tokenId;
    uint256 price;
    uint256 startBlockTimestamp;
    uint256 endBlockTimestamp;
    address buy;
    bool isSold;
}
