// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./OwnableUDS.sol";
import "./UUPSUpgrade.sol";
import "./AccessControlUDS.sol";
import "./FxERC20RelayRoot.sol";

/// @title Jira Token Root Relay
/// @notice Flexible ERC20 Token Relay
/// @author phaze (https://github.com/0xPhaze/fx-contracts)
contract JiraTokenRootRelay is UUPSUpgrade, OwnableUDS, FxERC20RelayRoot {
    constructor(
        address jira,
        address checkpointManager,
        address fxRoot
    ) FxERC20RelayRoot(jira, checkpointManager, fxRoot) {
        __Ownable_init();
    }

    /* ------------- owner ------------- */

    function _authorizeUpgrade() internal override onlyOwner {}

    function _authorizeTunnelController() internal override onlyOwner {}
}
