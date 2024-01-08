// contracts/sophiafaces.sol
// SPDX-License-Identifier: MIT

//    ___.   .__                 __      _____                            
//    \_ |__ |  |   ____   ____ |  | ___/ ____\____    ____  ____   ______
//    | __ \|  |  /  _ \_/ ___\|  |/ /\   __\\__  \ _/ ___\/ __ \ /  ___/
//    | \_\ \  |_(  <_> )  \___|    <  |  |   / __ \\  \__\  ___/ \___ \ 
//    |___  /____/\____/ \___  >__|_ \ |__|  (____  /\___  >__a_  >____  >
//        \/                 \/     \/            \/     \/    \/     \/ 


pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";

// sophiafaces - a blockfaces production

abstract contract Blockfaces {
  function walletOfOwner(address _owner) public virtual view returns(uint256[] memory);
}

contract sophiafaces is ERC721Enumerable, Ownable {
    
    using Strings for uint256;
    Blockfaces private blockface;
    
    bool public hasSaleStarted;
    uint256 private _price = 0.06 ether;
    uint256 private _holderprice = 0.04 ether;
    string _baseTokenURI;
    
    
    // The IPFS hash
    string public METADATA_PROVENANCE_HASH = "";
    
    // Truth
    string public constant R = "sophiafaces - the girl with the thousand faces";

    constructor(string memory baseURI) ERC721("Sophiafaces","SFACES")  {
        setBaseURI(baseURI);
        blockface = Blockfaces(0x8Ab89E0191F71903F97709d4b4653922D62e6Bfb);
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
        uint256[] memory blockfaceids;
        blockfaceids = blockface.walletOfOwner(msg.sender);
        uint256 balance = blockfaceids.length;
        uint256 supply = totalSupply();
        
        require(hasSaleStarted,                                 "sale is paused");
        require(numfaces < 26,                                  "only up to 25 Sophias at once");
        require(supply + numfaces < 1001,                       "exceeds max Sophias");

        if(balance > 0){
            require(msg.value >= _holderprice * numfaces,             "ether value sent is below the price");
            for(uint256 i; i < numfaces; i++){
                _safeMint( msg.sender, supply + i );
            }
        }
        else{
            require(msg.value >= _price * numfaces,             "ether value sent is below the price");
            for(uint256 i; i < numfaces; i++){
                _safeMint( msg.sender, supply + i );
            }
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
    
    function setHolderPrice(uint256 _newPrice) public onlyOwner() {
        _holderprice = _newPrice;
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
        require(supply < 11, "no more reserves allowed");
        for(uint256 i; i < 10; i++){
            _safeMint( msg.sender, supply + i );
        }
    }
}

