//  ________  ___       ___  ___  ________  ________  ________  ________  _______
// |\   ____\|\  \     |\  \|\  \|\   __  \|\   __  \|\   __  \|\   __  \|\  ___ \
// \ \  \___|\ \  \    \ \  \\\  \ \  \|\ /\ \  \|\  \ \  \|\  \ \  \|\  \ \   __/|
//  \ \  \    \ \  \    \ \  \\\  \ \   __  \ \   _  _\ \   __  \ \   _  _\ \  \_|/__
//   \ \  \____\ \  \____\ \  \\\  \ \  \|\  \ \  \\  \\ \  \ \  \ \  \\  \\ \  \_|\ \
//    \ \_______\ \_______\ \_______\ \_______\ \__\\ _\\ \__\ \__\ \__\\ _\\ \_______\
//     \|_______|\|_______|\|_______|\|_______|\|__|\|__|\|__|\|__|\|__|\|__|\|_______|
//
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract LLCSalesData {
    struct LLCMintingRound {
        uint256 mintingFee;
        uint256 startTime;
        uint256 endTime;
        uint256 participants;
        bytes32 merkleRoot;
    }

    struct LLCMintingRoundStatus {
        uint256 volume;
        uint256 participants;
    }

    /// @dev Minting rounds
    LLCMintingRound[] public rounds;

    /// @dev Minting Round participants
    mapping(uint256 => mapping(address => bool)) public participants;

    /// @dev Minting Round status
    mapping(uint256 => LLCMintingRoundStatus) public roundStatus;

    event NewSaleRound(uint256 mintingFee, uint256 startTime, uint256 endTime, bytes32 merkleRoot);
    event NewParticipant(uint256 roundId, address who);
}
