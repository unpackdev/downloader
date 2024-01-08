// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

/// @notice functions that can be called by a game controller
interface IBLOODBAG {
    /// @notice make a $BLOODBAG transfusion from the gods to a specified address
    /// @param to the addres getting the $BLOODBAG
    /// @param amount the amount of $BLOODBAG to mint
    function mint(address to, uint256 amount) external;

    /// @notice flush some $BLOODBAG down the toilet (burn)
    /// @param from the holder of the $BLOODBAG
    /// @param amount the amount of $BLOODBAG to burn
    function burn(address from, uint256 amount) external;
}
