// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

enum TicketType {
    GOLD,
    PLATINUM,
    LIFETIME
}

struct TicketInfo {
    uint16 id;
    TicketType typ;
    uint32 expiration;
    uint32 renewalPeriod;
    uint128 renewalPrice;
}