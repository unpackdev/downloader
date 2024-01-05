// contracts/CustomBuilds.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0; // Was >=0.4.22 <0.8.0

import "./ERC721.sol";
import "./Ownable.sol";
import "./Counters.sol";

// My friend really wants me to make an NFT.. Here goes!
contract CustomBuildsGPU is ERC721, Ownable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIds;

    uint256 public constant MAX_GPU_COUNT = 10000;
    bool saleActive = false;

    // When possible, the hash of the text file containing all card names will be added here
    string public METADATA_PROVENANCE_HASH = "";

    constructor(string memory baseURI) ERC721("CustomBuilds GPU", "GPU") public {
        setBaseURI(baseURI);
    }

    // Modifiers

    modifier saleIsOn() {
        require(saleActive, "Sale needs to be started first");
        _;
    }

    modifier saleIsOff() {
        require(!saleActive, "Sale is currently active");
        _;
    }

    // The Fun Part

    function unboxCards(uint8 numCards) public payable saleIsOn {
        require(numCards >= 1 && numCards <= 20, "Only 1 to 20 cards at once");

        require(
            totalSupply().add(numCards) <= MAX_GPU_COUNT,
            "Exceeds max number of cards"
        );

        require(
            msg.value >= calculatePresalePrice().mul(numCards),
            "Ether is insufficient for the total price"
        );

        for (uint8 i = 0; i < numCards; i++) {
            _tokenIds.increment();
            _safeMint(msg.sender, _tokenIds.current());
        }
    }

    // Inspired/copied from Chubbies (Thnx <3!)
    function calculatePresalePrice() public view returns (uint256) {
        uint256 currentSupply = totalSupply();

        if (currentSupply >= 9900) {
            return 1000000000000000000; // 9900-10000: 1.00 ETH
        } else if (currentSupply >= 9500) {
            return 640000000000000000; // 9500-9500:  0.64 ETH
        } else if (currentSupply >= 7500) {
            return 320000000000000000; // 7500-9500:  0.32 ETH
        } else if (currentSupply >= 3500) {
            return 160000000000000000; // 3500-7500:  0.16 ETH
        } else if (currentSupply >= 1500) {
            return 80000000000000000; // 1500-3500:  0.08 ETH
        } else if (currentSupply >= 500) {
            return 40000000000000000; // 500-1500:   0.04 ETH
        } else {
            return 20000000000000000; // 0 - 500     0.02 ETH
        }
    }

    // Administration

    function setProvenanceHash(string memory _hash) public onlyOwner {
        METADATA_PROVENANCE_HASH = _hash;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _setBaseURI(baseURI);
    }

    function beginSale() public onlyOwner saleIsOff {
        saleActive = true;
    }

    function pauseSale() public onlyOwner saleIsOn {
        saleActive = false;
    }

    function withdrawAll() public payable onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }

    function reserveGiveaway(uint8 numCards)
        public
        onlyOwner
        saleIsOff
    {
        uint256 currentSupply = totalSupply();
  
        require(currentSupply.add(numCards) <= 30, "Exceeds giveaway limit");

        require(
            currentSupply.add(numCards) <= MAX_GPU_COUNT,
            "Exceeds max number of cards"
        );

        // Reserved for people who helped this project and giveaways
        for (uint8 index = 0; index < numCards; index++) {
            _tokenIds.increment();
            _safeMint(owner(), _tokenIds.current());
        }
    }
}
