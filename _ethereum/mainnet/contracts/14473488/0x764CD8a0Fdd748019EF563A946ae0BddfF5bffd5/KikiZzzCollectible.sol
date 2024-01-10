// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "ERC721URIStorage.sol";

contract KikiZzzCollectible is ERC721URIStorage {
    uint256 public tokenCounter;
    address public owner;

    constructor() public ERC721("KikiZzz", "KIKI") {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function createCollectible(string memory tokenURI)
        public
        onlyOwner
        returns (uint256)
    {
        uint256 newTokenId = tokenCounter + 1;
        _safeMint(msg.sender, newTokenId);
        _setTokenURI(newTokenId, tokenURI);
        tokenCounter = newTokenId;
        return newTokenId;
    }
}
