// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "./ERC721.sol";
import "./Ownable.sol";

contract Charlows is ERC721, Ownable {
    using SafeMath for uint256;
    uint public constant MAX_CHARLOWS = 10000;
    bool public hasSaleStarted = false;
    
    // The IPFS hash for all Charlows - TBD
    string public METADATA_PROVENANCE_HASH = "";

    // woof　
    string public constant woof = "woof";

    constructor(string memory baseURI) public ERC721("Charlows","CHARLOWS")  {
        setBaseURI(baseURI);
    }
    
    function tokensOfOwner(address _owner) external view returns(uint256[] memory ) {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            // Return an empty array
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 index;
            for (index = 0; index < tokenCount; index++) {
                result[index] = tokenOfOwnerByIndex(_owner, index);
            }
            return result;
        }
    }
    
    function calculatePrice() public view returns (uint256) {
        require(hasSaleStarted == true, "Sale hasn't started");
        require(totalSupply() < MAX_CHARLOWS, "Sale has already ended");

        uint currentSupply = totalSupply();
        if (currentSupply >= 7501) {
            return 400000000000000000;         // 7501-10000: 0.40 ETH
        } else if (currentSupply >= 5001) {
            return 200000000000000000;         // 5001-7500:  0.20 ETH
        } else if (currentSupply >= 2501) {
            return 100000000000000000;         // 2501-5000:  0.10 ETH
        } else if (currentSupply >= 501) {
            return 50000000000000000;          // 501-2500:   0.05 ETH
        } else {
            return 10000000000000000;          // 0 - 500     0.01 ETH
        }
    }

    function calculatePriceForToken(uint _id) public view returns (uint256) {
        require(_id < MAX_CHARLOWS, "Sale has already ended");

        if (_id >= 7501) {
            return 400000000000000000;        // 7501-10000: 0.40 ETH
        } else if (_id >= 5001) {
            return 200000000000000000;         // 5001-7500:  0.20 ETH
        } else if (_id >= 2501) {
            return 100000000000000000;         // 2501-5000:  0.10 ETH
        } else if (_id >= 501) {
            return 50000000000000000;         // 501-2500:   0.05 ETH
        } else {
            return 10000000000000000;          // 0 - 500     0.01 ETH
        }
    }
    
   function adoptCharlow(uint256 numCharlows) public payable {
        require(totalSupply() < MAX_CHARLOWS, "Sale has already ended");
        require(numCharlows > 0 && numCharlows <= 20, "You can adopt minimum 1, maximum 20 Charlows");
        require(totalSupply().add(numCharlows) <= MAX_CHARLOWS, "Exceeds MAX_CHARLOWS");
        require(msg.value >= calculatePrice().mul(numCharlows), "Ether value sent is below the price");

        for (uint i = 0; i < numCharlows; i++) {
            uint mintIndex = totalSupply().add(1); //we start from tokenId = 1, not from 0
            _safeMint(msg.sender, mintIndex);
        }
    }
    
    // Dog Mode
    function setProvenanceHash(string memory _hash) public onlyOwner {
        METADATA_PROVENANCE_HASH = _hash;
    }
    
    function setBaseURI(string memory baseURI) public onlyOwner {
        _setBaseURI(baseURI);
    }
    
    function startSale() public onlyOwner {
        hasSaleStarted = true;
    }
    function pauseSale() public onlyOwner {
        hasSaleStarted = false;
    }
    
    function withdrawAll() public payable onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }
}











