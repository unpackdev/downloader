// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "./ERC721Enumerable.sol";
import "./ERC721.sol";
import "./Ownable.sol";

contract seedsbyboldart is ERC721, Ownable 
{
    using Strings for string;

    uint public constant MAX_TOKENS = 4096;
    uint256 public constant PRICE = 50000000000000000; //0.05 eth in wei
    bool public saleIsActive = false;
    uint public supply = 0;
    string private _baseTokenURI;
    address payable private devguy = payable(0x0F7961EE81B7cB2B859157E9c0D7b1A1D9D35A5D);
    

    constructor() ERC721("SEEDS by BOLD.ART", "SEEDS") 
    {
        //mints 4 tokens for the team
        for (uint i = 0; i < 4; i++) 
        {
            _safeMint(msg.sender, supply);
            supply++;
        }
    }

    function mintToken(uint256 numTokens) external payable
    {
        require(saleIsActive, "Sale must be active to mint");
        require(supply + numTokens <= MAX_TOKENS, "Purchase would exceed max supply");
        require(numTokens > 0 && numTokens <= 5, "Max 5 NFTs");
        require(msg.value == PRICE * numTokens, "Wrong ETH value");

        for (uint i = 0; i < numTokens; i++) 
        {
            _safeMint(msg.sender, supply);
            supply++;
        }
    }

    function flipSaleState() external onlyOwner 
    {
        saleIsActive = !saleIsActive;
    }
    
    function withdraw() external 
    {
        require(msg.sender == devguy || msg.sender == owner(), "Invalid sender");

        uint devPart = address(this).balance / 100 * 6;
        devguy.transfer(devPart);
        payable(owner()).transfer(address(this).balance);
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
