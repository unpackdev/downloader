// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.4;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract PotatoesTheBusiness is ERC721Enumerable, Ownable {

    // Potatoes sale setup
    uint256 public constant SALE_ENDING_BLOCK = 13156000;
    uint256 public constant POTATOES_SUPPLY = 5100;
    uint256 public constant RESERVED = 100;
    uint256 public constant PRICE = 0.15 ether;
    uint256 public constant MAX_POTATOES_PER_CLIENT = 20;
    string _baseTokenURI;

    // Kick off
    constructor(string memory name, string memory symbol, string memory baseURI) ERC721(name, symbol) {
        _baseTokenURI = baseURI;
    }

    // Buy potatoes
    function buyPotatoes(uint256 numberOfPotatoes) public payable {
        uint potatoesSold = totalSupply();
        require(block.number < SALE_ENDING_BLOCK, "Sale is finished, thank you for participating!");
        require(0 < numberOfPotatoes && numberOfPotatoes <= MAX_POTATOES_PER_CLIENT, "You can get maximum 20 potatoes. Watch out for stomach inflammation." );
        require((potatoesSold + numberOfPotatoes) < (POTATOES_SUPPLY - RESERVED), "No more potatoes to sell!");
        require(PRICE * numberOfPotatoes <= msg.value, "Incorrect price. Please respect the potato!");

        for(uint256 i; i < numberOfPotatoes; i++){
            _safeMint(msg.sender, potatoesSold + i);
        }
    }

    // Collect potatoes as a farmer
    function collectPotatoes(uint256 numberOfPotatoes) onlyOwner public {
        uint potatoesSold = totalSupply();
        require((potatoesSold + numberOfPotatoes) < POTATOES_SUPPLY, "No more potatoes to collect!");

        for(uint256 i; i < numberOfPotatoes; i++){
            _safeMint(msg.sender, potatoesSold + i);
        }
    }

    // Send someone a hot potato
    function sendPotatoes(address luckyReceiver, uint256 numberOfPotatoes) onlyOwner public {
        uint potatoesSold = totalSupply();
        require((potatoesSold + numberOfPotatoes) < POTATOES_SUPPLY, "No more potatoes to send!");

        for(uint256 i; i < numberOfPotatoes; i++){
            _safeMint(luckyReceiver, potatoesSold + i);
        }
    }

    // Collect takings
    function withdraw() onlyOwner public {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    // Cleanup base URI
    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }
    
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }
}