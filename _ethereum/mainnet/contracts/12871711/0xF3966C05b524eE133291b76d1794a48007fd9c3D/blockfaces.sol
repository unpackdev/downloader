// contracts/blockfaces.sol
// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "./ERC721.sol";
import "./Ownable.sol";

// inspired(by)/copied(from) BGANPUNKS,MUBBIES,COOLCATS

contract blockfaces is ERC721, Ownable {
    
    using SafeMath for uint256;
    bool public hasSaleStarted = false;
    uint256 private _price = 0.05 ether;
    
    // The IPFS hash
    string public METADATA_PROVENANCE_HASH = "";

    constructor(string memory baseURI) ERC721("blockfaces","BFACES")  {
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
    
    function adopt(uint256 numfaces) public payable {
        uint256 supply = totalSupply();
        require(hasSaleStarted,                         "sale is paused");
        require(numfaces < 21,                          "only up to 20 blockfaces at once");
        require(supply + numfaces < 5000,               "exceeds max faces");
        require(msg.value >= _price * numfaces,         "ether value sent is below the price");

        for(uint256 i; i < numfaces; i++){
            _safeMint( msg.sender, supply + i );
        }
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
    
    function withdrawAll() public payable onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }

    // community reserve
    function reserve() public onlyOwner {
        uint256 supply = totalSupply();
        require(supply == 0, "looks like the sale has already started!");
        for(uint256 i; i < 50; i++){
            _safeMint( msg.sender, supply + i );
        }
    }
}