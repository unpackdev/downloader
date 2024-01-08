// contracts/guttercatloot.sol
// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "./ERC721.sol";
import "./Ownable.sol";

// inspired by the notorious B.I.G.

contract guttercatloot is ERC721, Ownable {
    
    using SafeMath for uint256;
    bool public hasSaleStarted = true;
    bool public hasBurnStarted = false;
    uint256 private _price = 0.025 ether;
    
    // The IPFS hash
    string public METADATA_PROVENANCE_HASH = "";

    constructor(string memory baseURI) ERC721("guttercatloot","GCLOOT")  {
        setBaseURI(baseURI);        
    }
    
    function walletOfOwner(address _owner) public view returns(uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for(uint256 i; i < tokenCount; i++){
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }
    
    function gimmetheloot(uint256 numgcloot) public payable {
        uint256 supply = totalSupply() + 1;
        require(hasSaleStarted,                             "sale is paused");
        require(numgcloot < 51,                             "only up to 50 gcloot at once");
        require(supply + numgcloot < 3001,                  "exceeds max gcloot");
        require(msg.value >= _price * numgcloot,            "ether value sent is below the price");

        for(uint256 i; i < numgcloot; i++){
            _safeMint( msg.sender, supply + i );
        }
    }
    
    function burntheloot(uint256 tokenId) public {
        require(hasBurnStarted,                             "no burning allowed");
        require(_isApprovedOrOwner(msg.sender, tokenId),    "you cant burn this one");
        _burn(tokenId);
    }

    // a higher power
    function setProvenanceHash(string memory _hash) public onlyOwner {
        METADATA_PROVENANCE_HASH = _hash;
    }
    
    function setBaseURI(string memory baseURI) public onlyOwner {
        _setBaseURI(baseURI);
    }
    
    function setPrice(uint256 _newPrice) public onlyOwner() {
        _price = _newPrice;
    }
    
    function startSale() public onlyOwner {
        hasSaleStarted = true;
    }
    function pauseSale() public onlyOwner {
        hasSaleStarted = false;
    }
    
    function startBurn() public onlyOwner {
        hasBurnStarted = true;
    }

    function pauseBurn() public onlyOwner {
        hasBurnStarted = false;
    }

    function withdrawAll() public payable onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }
}