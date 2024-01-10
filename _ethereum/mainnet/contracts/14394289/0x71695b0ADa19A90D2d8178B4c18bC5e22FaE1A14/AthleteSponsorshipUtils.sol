// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

library AthleteSponsorshipUtils {
    enum NftType {
        None,
        Weekend1,
        Weekend2,
        Weekend3,
        Origin
    }

    struct SponsorshipRoundInfo {
        uint16 season;
        NftType nft_type;
        bytes32 location;
        uint16 capacity;
        bool is_open;
    }

    struct AthleteSponsorship {
        uint256 athlete_id;
        uint256 round_id;
        // sponsorship availability
        uint16 claimed;
        // funding (escrow vs. sent to ath wallet)
        uint256 funds_committed;
        bool funds_claimed_by_athlete;
        bool refund_eligible;
    }

    struct SponsorshipOrigination {
        uint256 price;
        uint256 athlete_sponsorship_id;
        uint16 serial;
    }
}
