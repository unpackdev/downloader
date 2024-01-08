// SPDX-License-Identifier: MIT
// Copyright 2021 Arran Schlosberg
pragma solidity >=0.8.0 <0.9.0;

import "./Ownable.sol";
import "./Pausable.sol";

/// @notice A Pausable contract that can only be toggled by the Owner.
contract OwnerPausable is Ownable, Pausable {
    /// @notice Pauses the contract.
    function pause() onlyOwner public {
        Pausable._pause();
    }

    /// @notice Unpauses the contract.
    function unpause() onlyOwner public {
        Pausable._unpause();
    }
}