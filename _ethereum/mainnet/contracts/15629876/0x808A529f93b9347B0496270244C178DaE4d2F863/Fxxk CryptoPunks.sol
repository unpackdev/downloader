// SPDX-License-Identifier: MIT
// Made by @Web3Club

pragma solidity ^0.8.4;

import "./ERC721A.sol";

contract HugYourHippo is ERC721A {

    uint256 public constant USER_LIMIT = 1;
    uint256 public constant MAX_SUPPLY = 999;
    

    constructor() ERC721A("Fxxk CryptoPunks", "FCP") {}

    function mint(uint256 quantity) external {
        require(_totalMinted() + quantity <= MAX_SUPPLY, "Not more supply left");
        require(_numberMinted(msg.sender) + quantity <= USER_LIMIT, "User limit reached");
        // add allowlist verification here
        _mint(msg.sender, quantity);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return "ipfs://QmadXarDuWa4aYQhu8aUyAcZFBZh5iN283thmGnUY5nvBp/";
    }
}