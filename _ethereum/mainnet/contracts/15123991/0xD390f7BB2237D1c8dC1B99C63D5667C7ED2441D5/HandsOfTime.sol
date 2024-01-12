// SPDX-License-Identifier: GPL-3.0-or-later

/// @title Hands of Time by Rich Caldwell
/// @author transientlabs.xyz

pragma solidity ^0.8.9;

import "ERC721TLCreator.sol";

contract HandsOfTime is ERC721TLCreator {

    constructor(address _royaltyRecipient, uint256 _royaltyPercentage, address _admin)
    ERC721TLCreator("Hands of Time", "HoT", _royaltyRecipient, _royaltyPercentage, _admin)
    {}
}