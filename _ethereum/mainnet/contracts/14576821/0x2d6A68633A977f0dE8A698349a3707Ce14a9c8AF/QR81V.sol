//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC721.sol";
import "./Ownable.sol";

contract QR81V is ERC721, Ownable {
    constructor(string memory tokenName, string memory symbol, address newOwner) ERC721(tokenName, symbol) {
    }

    function _baseURI() internal pure override returns (string memory) {
        return "ipfs://QmaioaqyN7hGmhzmdA3bEQrYrYQPfY37im6gMgnZuANACK/";
    }

    function mint(address to, uint256 tokenId) public onlyOwner {
        // require(msg.sender == owner(), "msg.sender is not owner");
        _safeMint(to, tokenId);
    }
}