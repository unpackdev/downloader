// SPDX-License-Identifier: GPL-3.0-or-later

/// @title Vertigo by Tyler Lekki
/// @author transientlabs.xyz

pragma solidity ^0.8.9;

import "ERC721TLCreator.sol";

contract Vertigo is ERC721TLCreator {

    constructor(address _royaltyRecipient, uint256 _royaltyPercentage, address _admin)
    ERC721TLCreator("Vertigo", "VRT", _royaltyRecipient, _royaltyPercentage, _admin)
    {}
}