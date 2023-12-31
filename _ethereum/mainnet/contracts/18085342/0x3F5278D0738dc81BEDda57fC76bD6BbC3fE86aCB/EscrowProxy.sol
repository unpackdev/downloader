// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./ERC1967Proxy.sol";

contract EscrowProxy is ERC1967Proxy {
    /// @notice Initializes the EndState Escrow via UUPS.
    /// @param logic The address of the EndState Escrow implementation.
    /// @param data ABI-encoded EndState Escrow initialization data.
    constructor(address logic, bytes memory data) ERC1967Proxy(logic, data) {}
}
