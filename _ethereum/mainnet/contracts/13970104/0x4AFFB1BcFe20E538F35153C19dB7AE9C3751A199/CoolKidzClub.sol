// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract CoolKidzClub is ERC721Enumerable, Ownable {  
    using Address for address;
    
    // Starting and stopping sale
    bool public active = false;

    // Maximum limit of tokens that can ever exist
    uint256 constant MAX_SUPPLY = 5555;

    // The base link that leads to the image / video of the token
    string public baseTokenURI;

    constructor (string memory newBaseURI) ERC721 ("Cool Kidz Club", "CKC") {
        setBaseURI(newBaseURI);
    }

    // Override so the openzeppelin tokenURI() method will use this method to create the full tokenURI instead
    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    // See which address owns which tokens
    function tokensOfOwner(address addr) public view returns(uint256[] memory) {
        uint256 tokenCount = balanceOf(addr);
        uint256[] memory tokensId = new uint256[](tokenCount);
        for(uint256 i; i < tokenCount; i++){
            tokensId[i] = tokenOfOwnerByIndex(addr, i);
        }
        return tokensId;
    }

    // Standard mint function
    function mintToken(uint256 _amount) public {
        uint256 supply = totalSupply();
        require( active,                         "Sale isn't active" );
        require( _amount > 0 && _amount < 6,     "Can only mint between 1 and 5 tokens at once" );
        require( supply + _amount <= MAX_SUPPLY, "Can't mint more than max supply" );
        for(uint256 i; i < _amount; i++){
            _safeMint( msg.sender, supply + i );
        }
    }

    // Start and stop sale
    function setActive(bool val) public onlyOwner {
        active = val;
    }

    // Set new baseURI
    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
    }
}