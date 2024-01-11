// SPDX-License-Identifier: MIT

/// @title NFTSEA Tickets
/// @author Transient Labs

pragma solidity ^0.8.9;

import "ERC1155TLCore.sol";

contract NFTSEATickets is ERC1155TLCore {

    constructor (address _admin, address _payout) ERC1155TLCore(_admin, _payout, "NFTSEA Tickets by NFT Access & Transient Labs") {}

    function setMerkleRoot(uint256 _tokenId, bytes32 _merkleRoot) external adminOrOwner {
        require(tokenDetails[_tokenId].created, "Token ID not valid");
        tokenDetails[_tokenId].merkleRoot = _merkleRoot;
    }

    function setAvailableSupply(uint256 _tokenId, uint64 _supply) external adminOrOwner {
        require(tokenDetails[_tokenId].created, "Token ID not valid");
        tokenDetails[_tokenId].availableSupply = _supply;
    }
}