// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.13;

struct CollectionConfig {
    bytes16 uuid;
    string name;
    string token;
    string slug;
    bytes16[] dependencies;
    string[] metadataKeys;
    string[] metadataValues;
}

enum SaleType {
    FixedPrice,
    DeprecatedReserved,
    ExponentialDutchAuction,
    FixedPriceTimeLimited
}

struct SaleConfig {
    SaleType saleType; // uint8 for packing
    uint32 maxSalePieces; // Maximum number of pieces to sell (including reserves)
    uint32 numReserved; // Number of pieces to reserve for specific wallets
    uint16 numRetained; // Number of pieces to retain for the artist
    uint16 numAlba; // Number of pieces to retain for Alba
    uint40 startTime; // Sale start time
    uint40 auctionEndTime; // Sale doesn't stop here, but price decay stops. Needed for rebate if non-sellout.
    bool hasRebate; // Whether or not to give a rebate to resting price
    uint256 initialPrice; // Starting price for Dutch Auction
    uint256 finalPrice; // Ending price for Dutch Auction
}

struct PaymentConfig {
    address[] primaryPayees; // Addresses for primary payment.
    uint256[] primaryShareBasisPoints; // Share of primary sales for each address (basis points).
    address[] secondaryPayees; // Addresses for secondary payment.
    uint256[] secondaryShareBasisPoints; // Share of secondary sales for each address (basis points).
    uint16 royaltyBasisPoints; // Total royalty basis points.
}

struct StoredScript {
    string fileName;
    uint256 wrappedLength;
}
