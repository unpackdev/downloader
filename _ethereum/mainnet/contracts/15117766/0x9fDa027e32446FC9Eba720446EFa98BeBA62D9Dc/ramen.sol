// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./ERC721.sol";

contract RamenDAO is ERC721
 {
    uint256 private MAX_TOKENS = 150; 
    uint256 private counter = 0;
    address private owner;

    constructor() ERC721("RamenDAO by CNC", "RAMEN") {
        owner = msg.sender;
    }

    function tokenURI(uint256) public pure override returns (string memory) {
        return "ipfs://Qmbj7YdDZA9ByqR2mGXXf7e8UZTiBe3JivvTtb4aFdX3CY/";
    }

    function mint(uint256 amount) external payable {
        require(counter + amount < MAX_TOKENS, "No ramen left");
        require(
            amount <= 3,
            "Leave some ramen for the others ser"
        );
        require(0.05 ether * amount <= msg.value, "Inflation ser. Add more ETH");

        for (uint256 i = 0; i < amount; i++) {
            _safeMint(msg.sender, counter + i);
        }
        counter += amount;
    }

    function withdrawAll() external {
        payable(owner).transfer(address(this).balance);
    }

}