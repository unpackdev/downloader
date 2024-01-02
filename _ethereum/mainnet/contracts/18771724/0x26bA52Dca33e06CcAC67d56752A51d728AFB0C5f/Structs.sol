// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

enum CollateralType {
    ERC721,
    ERC1155,
    ERC721_WITH_CRITERIA,
    ERC1155_WITH_CRITERIA
}

struct Lien {
    address lender;
    address borrower;
    uint8 collateralType;
    address collection;
    uint256 tokenId;
    uint256 amount;
    address currency;
    uint256 borrowAmount;
    uint256 duration;
    uint256 rate;
    uint256 startTime;
}

struct LoanOffer {
    address lender;
    address collection;
    uint8 collateralType;
    uint256 collateralIdentifier;
    uint256 collateralAmount;
    address currency;
    uint256 totalAmount;
    uint256 minAmount;
    uint256 maxAmount;
    uint256 duration;
    uint256 rate;
    uint256 salt;
    uint256 expiration;
    Fee[] fees;
}

struct Fee {
    uint16 rate;
    address recipient;
}

struct OfferAuth {
    bytes32 offerHash;
    address taker;
    uint256 expiration;
    bytes32 collateralHash;
}
