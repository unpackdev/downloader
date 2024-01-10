// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IListing {
    enum Status {
        NEW, // Just listed
        IRO, // IRO phase of listing
        LIVE, // IRO over and not in a buyout
        BUYOUT, // Buyout in progress
        REDEEMED // Buyout successful
    }
}
