// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./ERC721Enumerable.sol";
import "./ERC721.sol";
import "./Ownable.sol";

/*
Crypto Skins Project
Diversity and representation matter in the metaverse. The metaverse will be a reflection of who we are, our aspirations, and our demons.

The Crypto Skins Project V1 is a collection of 10,000 unique skins. In V1, Each skin contains 7 characteristics: the type, hair & headwear, eyes & eyewear, facial hair, neck accessories, mouth props, and mouth.
V2 will add even more characteristics including age, race, culture, gender identity, and sexual orientation.

*This is a Framework. Feel free to use Crypto Skins in any way you want.*
*Note that this Project is not audited. Mint at your own risk.
*/

contract CryptoSkins is ERC721, Ownable 
{
    using Strings for string;

    uint public constant MAX_TOKENS = 10000;
    uint public constant NUMBER_RESERVED_TOKENS = 100;
    
    bool public saleIsActive = false;

    uint public reservedTokensMinted = 0;
    uint public supply = 0;
    string private _baseTokenURI;

    constructor() ERC721("Crypto Skins Project", "CSP") {}

    function mintToken(uint256 amount) external
    {
        require(saleIsActive, "Sale must be active to mint");
        require(amount > 0 && amount <= 10, "Max 10 NFTs");
        require(supply + amount <= MAX_TOKENS - (NUMBER_RESERVED_TOKENS - reservedTokensMinted), "Purchase would exceed max supply");
        
        for (uint i = 0; i < amount; i++) 
        {
            _safeMint(msg.sender, supply);
            supply++;
        }
    }

    function flipSaleState() external onlyOwner 
    {
        saleIsActive = !saleIsActive;
    }

    function mintReservedTokens(uint256 amount) external onlyOwner 
    {
        require(reservedTokensMinted + amount <= NUMBER_RESERVED_TOKENS, "This amount is more than max allowed");

        for (uint i = 0; i < amount; i++) 
        {
            _safeMint(owner(), supply);
            supply++;
            reservedTokensMinted++;
        }
    }

    ////
    //URI management part
    ////
    
    function _setBaseURI(string memory baseURI) internal virtual {
        _baseTokenURI = baseURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }
    
    function setBaseURI(string memory baseURI) external onlyOwner {
        _setBaseURI(baseURI);
    }
  
    function tokenURI(uint256 tokenId) public view override(ERC721) returns (string memory) {
        string memory _tokenURI = super.tokenURI(tokenId);
        return bytes(_tokenURI).length > 0 ? string(abi.encodePacked(_tokenURI, ".json")) : "";
    }
}