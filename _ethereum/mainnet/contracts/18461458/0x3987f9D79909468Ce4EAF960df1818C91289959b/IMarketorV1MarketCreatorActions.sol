// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

/// @title Permissioned pool actions
/// @notice Contains pool methods that may only be called by the factory owner
interface IMarketorV1MarketCreatorActions {
    function setMarketorByMarketCreator(address _owner) external;

    /// @notice Explain to an end user what this does
    /// @dev Explain to a developer any extra details
    function delMarketorByMarketCreator(address _owner) external;
}
