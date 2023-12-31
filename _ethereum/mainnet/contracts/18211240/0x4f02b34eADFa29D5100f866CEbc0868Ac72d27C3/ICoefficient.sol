// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

/// @title Coefficient
/// @notice IOT will get this coefficient by key to calculate amount of token equivilant to obseved data
interface ICoefficient {
    /// @notice Set `value` for `key`
    /// @param key Key (Example: CH4)
    /// @param value The coefficient of the key
    function setCoefficient(bytes32 key, int128 value) external;

    /// @notice Get coefficient by key
    /// @param key Key (Example: CH4)
    function getCoefficient(bytes32 key) external returns (int128);

    /// @notice Emitted when change coefficient
    /// @param key Key (Example: CH4)
    /// @param value The coefficient of the key
    event ChangeCoefficient(bytes32 indexed key, int128 value);
}
