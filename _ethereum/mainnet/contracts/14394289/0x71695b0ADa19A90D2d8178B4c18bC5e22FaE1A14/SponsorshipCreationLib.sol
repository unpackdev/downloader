// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./AthleteLib.sol";

library SponsorshipCreationLib {
    // price of sponsorship for v0
    uint256 constant SPONSOR_PRICE_V0 = 0.04 ether;

    struct AthleteInitArgs {
        uint256 db_id;
        bytes32 full_name;
        AthleteLib.Sport sport;
        uint8 number;
        AthleteLib.PlayerPosition position;
    }

    struct SponsorshipRoundInitArgs {
        uint256 db_id;
        uint16 season;
        uint256 round;
        bytes32 location;
        uint16 capacity;
    }

    struct OnChainInitAudit {
        bool init_athlete;
        bool init_sponsorship_round;
        uint16 sponsorship_serial;
    }
}
