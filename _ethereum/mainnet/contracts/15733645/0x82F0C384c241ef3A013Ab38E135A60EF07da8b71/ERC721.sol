// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./ERC721Configurable.sol";
import "./ERC721Royalty.sol";

contract ERC721 is ERC721Configurable {

    constructor(
        string memory baseURI,
        string memory name,
        string memory symbol,
        address royaltyReceiver,
        uint64 royaltyFee,
        uint64 endsAt,
        uint32 maxMint,
        uint32 maxSupply,
        uint64 price,
        uint64 startsAt
    ) ERC721Configurable(maxMint, maxSupply, name, symbol) ERC721Royalty(royaltyReceiver, royaltyFee) {
        setBaseURI(baseURI);
        setConfig(0, endsAt, maxMint, maxSupply, price, startsAt);
    }


    function withdraw() external onlyOwner {
        _withdraw(owner(), address(this).balance);
    }
}
