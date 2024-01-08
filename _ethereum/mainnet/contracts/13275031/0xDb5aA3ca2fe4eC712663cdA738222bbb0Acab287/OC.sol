// contracts/originalcocos.sol
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";

// the original cocos

contract OriginalCocos is ERC721Enumerable, Ownable {
    
    using Strings for uint256;
    bool public hasSaleStarted = false;
    uint256 private _price = 0.05 ether;
    string _baseTokenURI;
    
    // withdraw addresses
    address OC = 0xdacBffb7E314486686B6374fdD91C3814B735aEC;
    address SR = 0x82b6643Ce8Cd0Ab6664C44215039A3fe4c1660e5;
    
    // The IPFS hash
    string public METADATA_PROVENANCE_HASH = "";

    constructor(string memory baseURI) ERC721("Original Cocos","COCO")  {
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
    
    function adopt(uint256 numcocos) public payable {
        uint256 supply = totalSupply();
        require(hasSaleStarted,                             "sale is paused");
        require(numcocos < 21,                              "only up to 20 Cocos at once");
        require(supply + numcocos < 10001,                  "exceeds max Cocos");
        require(msg.value >= _price * numcocos,             "ether value sent is below the price");

        for(uint256 i; i < numcocos; i++){
            _safeMint( msg.sender, supply + i );
        }
    }
    
    // a higher power
    function setProvenanceHash(string memory _hash) public onlyOwner {
        METADATA_PROVENANCE_HASH = _hash;
    }
    
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
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
        uint256 _eighty = (address(this).balance * 4) / 5;
        uint256 _twenty = (address(this).balance) / 5;
        require(payable(OC).send(_eighty));
        require(payable(SR).send(_twenty));
    }

    // community reserve
    function reserve() public onlyOwner {
        uint256 supply = totalSupply();
        require(supply < 101, "no more reserves allowed");
        for(uint256 i; i < 50; i++){
            _safeMint( OC, supply + i );
        }
    }
}