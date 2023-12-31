// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: 2023 Brick Towers <support@bricktowers.io>
pragma solidity ^0.8.0;

/// @title Contract enables any address to emit an event on-chain to request a "Voluntary Exit" of a validator.
contract VoluntaryExit {
    /// @param pubkey Ethereum validator public key
    event VoluntaryExitRequested(bytes pubkey);

    /// @param pubkeys An array of Ethereum validator public keys
    function requestVoluntaryExit(bytes[] calldata pubkeys) external {
        for (uint256 i; i < pubkeys.length;) {
            emit VoluntaryExitRequested(pubkeys[i]);
            unchecked{++i;}
        }
    }
}