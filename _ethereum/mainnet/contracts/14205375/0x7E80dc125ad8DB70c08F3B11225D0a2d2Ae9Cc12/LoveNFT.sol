// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC1155.sol";  
import "./Ownable.sol";

contract LoveNFT is ERC1155, Ownable {

    uint256 public NFT_ID = 0;
    uint256 public constant MINT_PRICE = 0.01 ether;
    uint256 public constant LIMIT = 50000;
    mapping(address => string) public oath;

    constructor() ERC1155("https://zebwyzw29cjo.usemoralis.com/{id}.json") {
        
    }

    function mint(string memory lover1, string memory lover2) public payable {
        require(balanceOf(msg.sender, NFT_ID) == 0, "Already write Oath!");
        oath[msg.sender] = string(abi.encodePacked(lover1, " loves ", lover2, " forever"));
        require(NFT_ID + 1 <= LIMIT, "All NFT token minted");
        require(msg.value == MINT_PRICE, "Invalid Mint Price");
        _mint(msg.sender, NFT_ID, 1, "");
        NFT_ID += 1;
    }

    function checkOath(address account) public view returns(string memory) {
        return oath[account];
    }

    function withdrawFund() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    // Function to receive Ether. msg.data must be empty
    receive() external payable {}

    // Fallback function is called when msg.data is not empty
    fallback() external payable {}


}