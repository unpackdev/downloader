//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Counters.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./ERC721Enumerable.sol";

contract FastFoodMoonbirds is ERC721Enumerable, Ownable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    
    Counters.Counter private _tokenIds;

    uint public constant MAX_SUPPLY = 4000;

	uint public constant PRICE = 0 ether;
	uint public constant MAX_PER_MINT = 5;
    bool public paused = false;

    string public baseTokenURI;

    constructor(string memory baseURI) ERC721("Fast Food Moonbirds", "FFMB") {
    	setBaseURI(baseURI);
    }

    function reserveNFTs() public onlyOwner {
     uint totalMinted = _tokenIds.current();
     require(
        totalMinted.add(10) < MAX_SUPPLY, "Not enough NFTs"
     );
     for (uint i = 0; i < 10; i++) {
          _mintSingleNFT();
     }
	}

    function pause() public onlyOwner {
        paused = !paused;
    }

	function _baseURI() internal view virtual override returns (string memory) {
     return baseTokenURI;
	}
	    
	function setBaseURI(string memory _baseTokenURI) public onlyOwner {
	     baseTokenURI = _baseTokenURI;
	}  

	function mint(uint _mintQty) public payable {
	     uint totalMinted = _tokenIds.current();
	     require(!paused, "Contract Paused");

            require(
               totalMinted.add(_mintQty) <= MAX_SUPPLY, "Not enough NFTs left!"
             );
            require(
               _mintQty > 0 && _mintQty <= MAX_PER_MINT, 
               "Exceeds max mints per transaction."
             );
            require(
               msg.value >= PRICE.mul(_mintQty), 
               "Not enough ether to purchase NFTs."
             );
         
	     
	     for (uint i = 0; i < _mintQty; i++) {
	            _mintSingleNFT();
	     }
	}

	function _mintSingleNFT() private {
      uint newTokenID = _tokenIds.current();
      _safeMint(msg.sender, newTokenID);
      _tokenIds.increment();
	}

	function tokensOfOwner(address _owner) 
         external 
         view 
         returns (uint[] memory) {
     uint tokenCount = balanceOf(_owner);
     uint[] memory tokensId = new uint256[](tokenCount);
     for (uint i = 0; i < tokenCount; i++) {
          tokensId[i] = tokenOfOwnerByIndex(_owner, i);
     }
     
     return tokensId;
	}

	function withdraw() public payable onlyOwner {
     uint balance = address(this).balance;
     require(balance > 0, "No ether left to withdraw");
     (bool success, ) = (msg.sender).call{value: balance}("");
     require(success, "Transfer failed.");
	}
	
}

