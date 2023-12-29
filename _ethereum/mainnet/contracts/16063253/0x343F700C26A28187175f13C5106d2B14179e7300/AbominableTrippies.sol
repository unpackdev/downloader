// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Pausable.sol";
import "./Ownable.sol";

contract AbominableTrippies is ERC721Enumerable, Pausable, Ownable 
{
    uint256 public cost = 0.02 ether;
    string public baseURI = "https://trippies.com/abominables/metadata/";

    constructor() ERC721("Abominable Trippies", "ABOMTRP")     
    {        
        pause();
    }

    function contractURI() public view returns (string memory) 
    {
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, "contract.json")) : "";    
    }

    function setCost(uint256 newCost) public onlyOwner 
    {
        cost = newCost;
    }

    function _baseURI() internal view override returns (string memory) 
    {
        return baseURI;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner 
    {
        baseURI = _newBaseURI;
    }

    function pause() public onlyOwner 
    {
        _pause();
    }

    function unpause() public onlyOwner 
    {
        _unpause();
    }

    function mint(address to, uint quantity) public whenNotPaused payable
    {
        require(msg.sender == owner() || msg.value >= cost * quantity);

        for (uint i = 0; i < quantity; i++) 
        {
            uint256 newTokenId = totalSupply() + 1; 
            _safeMint(to, newTokenId);
        }
    }

    function withdraw() public onlyOwner 
    {   
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }
}
