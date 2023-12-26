// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IArbitratorData {
    /*//////////////////////////////////////////////////////////////
                             Data Structures
    //////////////////////////////////////////////////////////////*/

    enum BetMode {
        // Fixed bet size
        CLASSIC,
        // Bet size is strictly increasing and determined by the player
        VARIABLE,
        // Bet size is increasing linearly
        ANTE
    }

    enum RNGMode {
        // No odds of death
        ZERO,
        // Odds of death randomly selected between RAND_MIN and RAND_MAX
        RANDOM
    }

    struct Randomness {
        uint256 randomness;
        uint64 counter;
        uint256 id;
    }

    struct Tontine {
        // Asset used for Tontine
        address asset;
        // Available seats
        uint8 seats;
        // Bet Mode
        BetMode betMode;
        // RNG Mode
        RNGMode rngMode;
        // Balance
        uint128 balance;
        // Current bet amount
        uint128 bet;
        // State of all participants
        uint128 participantState;
        // Last time a bet was received, or game started
        uint64 lastBetTime;
        // Counter for rng
        uint32 counter;
        // Last player index on participant state
        uint8 lastIndex;
    }
}
