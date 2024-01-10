// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/presets/ERC721PresetMinterPauserAutoId.sol)

pragma solidity ^0.8.0;

import "./Counters.sol";

interface IKinectAirOpenAccess {
    enum Tier {
        NONE,
        ADVANCED_ACCESS,
        PRIORITY_ACCESS,
        FIRST_ACCESS
    }

    enum Benefit {
        NONE,
        FLIGHT_FREE,
        FLIGHT_DISCOUNT,
        FLY_IN,
        ART_PRINT
    }

    struct TierData {
        string name;
        uint256 price;
        uint32 max_supply;
        uint32 total_supply;
        // defaults for tier
        uint8 flights_free;
        uint8 flights_discount;
        uint8 art_prints;
        uint8 fly_in;
        uint8 vote_weight;
    }

    struct TokenData {
        Tier tier;
        uint8 flights_free;
        uint8 flights_discount;
        uint8 art_prints;
        uint8 fly_in;
        uint8 vote_weight;
    }

    event TransferOpenAccess(address indexed from, address indexed to, uint256 tokenId, Tier tier);

    event TierUpdated(Tier tier, TierData old, TierData data);
    event ImageBaseUpdated(string old, string image);
    event RoyaltyAddressUpdated(address old, address reciever);
    event RoyaltyAmountUpdated(uint16 old, uint16 amount);
    event TokenDataUpdated(uint256 tokenId, TokenData old, TokenData data);
}
