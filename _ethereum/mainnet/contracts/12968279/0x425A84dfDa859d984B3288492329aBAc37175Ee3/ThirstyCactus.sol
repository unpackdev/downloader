// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "./ERC721.sol";
import "./Ownable.sol";

/**
 * @title Thirsty Cactus Contract - we need more water
 */

contract ThirstyCactus is ERC721, Ownable {
    using SafeMath for uint256;

    string public THIRSTYCACTUS_PROVENANCE = "";
    uint256 public constant tokenPrice = 25000000000000000; // 0.025 ETH
    uint public constant maxTokensPurchase = 20;
    uint public constant reservedTokens = 20;
    uint256 public constant maxTokens = 10000;
    bool public mintIsActive = false;

    constructor() ERC721("ThirstyCactus", "CACTUS") {
    }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        msg.sender.transfer(balance);
    }

   function reserveTokens() public onlyOwner {
        uint mintIndex = totalSupply();
        uint i;
        for (i = 0; i < reservedTokens; i++) {
            _safeMint(msg.sender, mintIndex + i);
        }
    }

    function flipMintState() public onlyOwner {
        mintIsActive = !mintIsActive;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _setBaseURI(baseURI);
    }

    function setProvenanceHash(string memory provenanceHash) public onlyOwner {
        THIRSTYCACTUS_PROVENANCE = provenanceHash;
    }

    function mintCactus(uint numberOfTokens) public payable {
        require(mintIsActive, "Mint is not active.");
        require(numberOfTokens <= maxTokensPurchase, "You went over max tokens per transaction.");
        require(totalSupply().add(numberOfTokens) <= maxTokens, "Not enough tokens left to mint that many");
        require(tokenPrice.mul(numberOfTokens) <= msg.value, "You sent the incorrect amount of ETH.");

        for(uint i = 0; i < numberOfTokens; i++) {
            uint mintIndex = totalSupply();
            if (totalSupply() < maxTokens) {
                _safeMint(msg.sender, mintIndex);
            }
        }
    }

}