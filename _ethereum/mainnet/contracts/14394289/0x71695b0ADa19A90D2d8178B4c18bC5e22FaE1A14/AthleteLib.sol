// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

library AthleteLib {
    enum Sport {
        None,
        BasketballMens,
        BasketballWomens
    }

    enum PlayerPosition {
        None,
        Guard, // basketball - begin
        Forward,
        Center // basketball - finish
    }

    struct Athlete {
        bytes32 player_name;
        // sport-specific info
        Sport sport;
        uint8 player_number;
        PlayerPosition player_position;
    }
}
