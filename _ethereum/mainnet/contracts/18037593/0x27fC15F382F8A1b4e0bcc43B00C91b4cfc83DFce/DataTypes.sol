//SPDX-License-Identifier: MIT
pragma solidity ~0.8.20;

// specifies if only whitelisted wallets can purchase domains
uint8 constant WHITELIST_CAN_BUY = 1;
// specifies if whitelisted wallets can purchase without price
uint8 constant WHITELIST_NO_FEES = 2;

struct DomainListingDetails {
    bool listed;
    uint256 basePrice;
    Pricing[] prices;
    uint256 deadline;
    // [0]: paymentReceiver... etc
    address[] addresses;
}

struct Pricing {
    uint256 letters;
    uint256 price;
}

struct ReservedListing {
    string label;
    uint256 price;
}
