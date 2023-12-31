// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./ERC1967Proxy.sol";

contract OrderBookProxy is ERC1967Proxy {
    /// @notice Initializes the EndState OrderBook via UUPS.
    /// @param logic The address of the EndState OrderBook implementation.
    /// @param data ABI-encoded EndState OrderBook initialization data.
    constructor(address logic, bytes memory data) ERC1967Proxy(logic, data) {}
}
