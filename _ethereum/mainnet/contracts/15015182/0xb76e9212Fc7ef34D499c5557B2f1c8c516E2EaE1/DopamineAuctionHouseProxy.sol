// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

////////////////////////////////////////////////////////////////////////////////
///              ░▒█▀▀▄░█▀▀█░▒█▀▀█░█▀▀▄░▒█▀▄▀█░▄█░░▒█▄░▒█░▒█▀▀▀              ///
///              ░▒█░▒█░█▄▀█░▒█▄▄█▒█▄▄█░▒█▒█▒█░░█▒░▒█▒█▒█░▒█▀▀▀              ///
///              ░▒█▄▄█░█▄▄█░▒█░░░▒█░▒█░▒█░░▒█░▄█▄░▒█░░▀█░▒█▄▄▄              ///
////////////////////////////////////////////////////////////////////////////////

import "./ERC1967Proxy.sol";

/// @title Dopamine Auction House Proxy Contract
/// @notice This contract serves as the UUPS proxy for upgrading and
///  initializing the Dopamine auction house implementation contract.
contract DopamineAuctionHouseProxy is ERC1967Proxy {

    /// @notice Initializes the Dopamine auction house via UUPS.
    /// @param logic The address of the Dopamine auction house implementation.
    /// @param data ABI-encoded Dopamine auction house initialization data.
    constructor(address logic, bytes memory data) ERC1967Proxy(logic, data) {}
}
