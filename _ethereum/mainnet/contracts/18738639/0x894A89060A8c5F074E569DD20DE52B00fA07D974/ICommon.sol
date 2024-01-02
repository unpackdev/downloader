// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

struct FactorySettings {
    address indelibleSecurity;
    address deployer;
    address operatorFilter;
}

struct RoyaltySettings {
    address royaltyAddress;
    uint96 royaltyAmount;
}

error NotAvailable();
error NotAuthorized();
error InvalidInput();
