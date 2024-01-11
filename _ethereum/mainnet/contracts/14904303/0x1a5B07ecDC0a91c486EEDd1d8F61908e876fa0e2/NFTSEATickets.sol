// SPDX-License-Identifier: MIT

/// @title NFTSEA Tickets
/// @author Transient Labs

pragma solidity ^0.8.9;

import "ERC1155TLCore.sol";

contract NFTSEATickets is ERC1155TLCore {

    constructor (address _admin, address _payout) ERC1155TLCore(_admin, _payout, "NFTSEA Tickets by NFT Access & Transient Labs") {}
}