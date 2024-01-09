// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

struct Rent {
    address originalOwner;

    uint256 tokenId;
    
    uint256 pricePerDay;

    uint256 startDate;
    uint256 endDate;
}
