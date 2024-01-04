// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";

interface IBridgeRelay {
    /**
     * @notice calls Polygon POS bridge for deposit
     * @dev the contract is designed in a way where anyone can call the function without risking funds
     * @dev MATIC cannot be bridged
     * @param token address of the token that is desired to be pushed accross the bridge
     */
    function bridgeTransfer(IERC20 token) external payable;

    /**
     * @dev Emitted when MATIC is attempted to be bridged
     */
    error MATICUnbridgeable();
}
