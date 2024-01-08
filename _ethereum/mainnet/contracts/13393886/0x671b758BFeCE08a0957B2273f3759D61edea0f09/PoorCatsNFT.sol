// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

import "./ERC721.sol";
import "./Ownable.sol";
import "./console.sol";


contract PoorCatsNFT is ERC721, Ownable {
    uint256 public constant startTime = 1633914000;

    uint256 public constant maxTokens = 9933;

    uint256 public constant maxMintsPerTx = 5;

    mapping(address => uint256) public addressToNumOwned;

    uint256 public tokenCounter;

    string baseURI_ = "";

    constructor()  ERC721("Poor Cats NFT", "POOR") {
        tokenCounter = 0;
    }

    function mint(uint256 amount) payable external {
        require(tokenCounter < maxTokens, "No remaining NFTs");
        require(amount <= maxMintsPerTx, "Too many mints per tx");
        require(addressToNumOwned[msg.sender] + amount <= 5,"Can't own more than 5 poor cats");
        require(block.timestamp >= startTime, "Too early");

        addressToNumOwned[msg.sender] = addressToNumOwned[msg.sender] + amount;

        for (uint256 i = 0; i < amount; i++) {
            _mint(msg.sender, tokenCounter);
            tokenCounter++;
        }
    }

    function _baseURI() internal view override returns (string memory) {
        return  baseURI_;
    }

    function setBaseUri(string calldata newURI) external onlyOwner {
        baseURI_ = newURI;
    }

    function ownerMint(address to, uint256 amount) external onlyOwner {
        require(tokenCounter < maxTokens, "No remaining NFTs");

        for (uint256 i = 0; i < amount; i++) {
            _mint(to, tokenCounter);
            tokenCounter++;
        }
    }
}