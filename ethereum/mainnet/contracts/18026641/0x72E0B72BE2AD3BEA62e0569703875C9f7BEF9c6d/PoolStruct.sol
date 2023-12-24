// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;


enum ItemType {
    NATIVE,
    ERC20,
    ERC721,
    ERC1155
}

struct Order {
    ItemType typ;
    address from;
    address to;
    address collection;
    uint256[] tokenIds;
    uint256[] amounts;
    uint256 salt;
    uint256 extraData;
    uint256 suitableTime;
    uint256 expiredTime;
}