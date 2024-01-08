// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "./IArchRouterImmutableState.sol";

/// @title Immutable state
/// @notice Immutable state used by periphery contracts
abstract contract ArchRouterImmutableState is IArchRouterImmutableState {
    /// @inheritdoc IArchRouterImmutableState
    address public immutable override uniV3Factory;
    /// @inheritdoc IArchRouterImmutableState
    address public immutable override WETH;

    constructor(address _uniV3Factory, address _WETH) {
        uniV3Factory = _uniV3Factory;
        WETH = _WETH;
    }
}
