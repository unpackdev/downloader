// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./FurLib.sol";

/// @title L2Lib
/// @author LFG Gaming LLC
/// @notice Utilities for L2
library L2Lib {

  // Payload for EIP-712 signature
  struct OAuthToken {
    address owner;
    uint32 access;
    uint64 deadline;
    bytes signature;
  }

  /// Loot changes on a token for resolve function
  struct LootResolution {
    uint256 tokenId;
    uint128 itemGained;
    uint128 itemLost;
  }

  /// Everything that can happen to a Furball in a single "round"
  struct RoundResolution {
    uint256 tokenId;
    uint32 expGained;     //
    uint8 zoneListNum;
    uint128[] items;
    uint64[] snackStacks;
  }

  // Signed message giving access to a set of expectations & constraints
  struct TimekeeperRequest {
    RoundResolution[] rounds;// What happened; passed by server.
    address sender;
    uint32 tickets;       // Tickets to be spent
    uint32 furGained;     // How much FUR the player expects
    uint32 furSpent;      // How much FUR the player spent
    uint32 furReal;       // The ACTUAL FUR the player earned (must be >= furGained)
    uint8 mintEdition;    // Mint a furball from this edition
    uint8 mintCount;      // Mint this many Furballs
    uint64 deadline;      // When it is good until
    // uint256[] movements;  // Moves made by furballs
  }

  // Track the results of a TimekeeperAuthorization
  struct TimekeeperResult {
    uint64 timestamp;
    uint8 errorCode;
  }

  // // Play = collect / move zones
  // struct ActionPlay {
  //   uint256[] tokenIds;
  //   uint32 zone;
  // }

  // // Snack = FurLib.Feeding

  // // Loot (upgrade)
  // struct ActionUpgrade {
  //   uint256 tokenId;
  //   uint128 lootId;
  //   uint8 chances;
  // }

  // // Signature package that accompanies moves
  // struct MoveSig {
  //   bytes signature;
  //   uint64 deadline;
  //   address actor;
  // }

  // // Signature + play actions
  // struct SignedPlayMove {
  //   bytes signature;
  //   uint64 deadline;
  //   // address actor;
  //   uint32 zone;
  //   uint256[] tokenIds;
  // }

  // // What does a player earn from pool?
  // struct PoolReward {
  //   address actor;
  //   uint32 fur;
  // }
}
