// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Ownable.sol";

error ExceedsMaxSupply();

contract PartyHorsesTicket is ERC721A, Ownable {
    // Max Supply
    uint256 public constant maxSupply = 400;

    // Base URI
    string public baseURI;

    constructor() ERC721A("Party Horses Party 2022", "PHPARTY22") {}

    // Starting Token ID at 1
    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    // Withdraw
    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    // Base URI
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory uri) external onlyOwner {
        baseURI = uri;
    }

    // Admin Mint
    function adminMint(uint256 quantity) external onlyOwner {
        if (totalSupply() + quantity > maxSupply) revert ExceedsMaxSupply();
        _safeMint(msg.sender, quantity);
    }

    // Always accept eth
    receive() external payable {}
}
