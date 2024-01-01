// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

/// @title Pool state that can change
/// @notice These methods compose the pool's state, and can change with any frequency including multiple times
/// per transaction
interface IMarketorV1State {
    function isValidMarketor() external view returns (bool);

    function isValidMarketor(address) external view returns (bool);
}
