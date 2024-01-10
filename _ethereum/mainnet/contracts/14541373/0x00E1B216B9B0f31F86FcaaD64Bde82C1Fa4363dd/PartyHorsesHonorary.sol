// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Ownable.sol";

contract PartyHorsesHonorary is ERC721A, Ownable {
    // Base URI
    string public baseURI;

    constructor() ERC721A("Party Horses Honorary Horses", "HONORARY") {}

    // Starting Token ID at 1
    function _startTokenId() internal pure override returns (uint256) {
        return 1;
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
        _safeMint(msg.sender, quantity);
    }

    // Always accept eth
    receive() external payable {}
    
    // Withdraw in case of eth sent
    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
}