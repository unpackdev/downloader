// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./ERC721A.sol";
import "./Ownable.sol";

contract Cybertown is ERC721A, Ownable {
    uint public maxFreeCap = 5000;
    uint public supply = 10000;
    uint public freePerWallet = 2;
    uint public mintPerWallet = 5; 
    bool public isFree = true;
    uint public price = 0.0088 ether;
    bool public pause = false;
    bool public activate = false;
    string public baseURI = "ipfs://QmacksnqfommWmdd6xeaogiGbofZSQBrVkLVs9GBVtCKcG/";

    constructor() ERC721A("cybertown.wtf", "CTWTF") {}

    function freemint(uint amt) external payable {
        require(!pause, "Paused");
        require(activate, "Inactive");
        require(isFree,"No more free");
        require(tx.origin == msg.sender, "wrong sender");
        require(supply >= totalSupply() + amt, "Sold out");
        require(amt > 0 && amt <= mintPerWallet,"Excess max allowed");
        require(_numberMinted(msg.sender) + amt <= mintPerWallet,"Max per wallet exceeded!");
        
        if(_numberMinted(msg.sender) >= freePerWallet){
            require(msg.value >= amt * price, "Insufficient funds");
        }else{
            uint qty = _numberMinted(msg.sender) + amt;
            if(qty > freePerWallet){
                require(msg.value >= (qty - freePerWallet) * price , "Insufficient funds");
            }   
        }
        _safeMint(_msgSender(), amt);
    }

    function mint(uint amt) external payable {
        require(!pause, "Paused");
        require(activate, "Inactive");
        require(tx.origin == msg.sender, "wrong sender");
        require(supply >= totalSupply() + amt, "Sold out");
        require(amt > 0 && amt <= mintPerWallet,"Excess max allowed");
        require(_numberMinted(msg.sender) + amt <= mintPerWallet,"Max per wallet exceeded!");
        require(msg.value >= amt * price, "Insufficient funds");
        _safeMint(_msgSender(), amt);
    }

    function withdraw() external onlyOwner {
        uint balance = address(this).balance;
        (bool success, ) = _msgSender().call{value: balance}("");
        require(success, "error");
    }

    function reduceSupply(uint amount) external onlyOwner {
        supply = amount;
    }

    function stop(bool value) external onlyOwner {
        pause = value;
    }

    function setFree(bool value) external onlyOwner {
        isFree = value;
    }

    function setActive(bool value) external onlyOwner {
        activate = value;
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    function setPrice(uint newPrice) external onlyOwner {
        price = newPrice;
    }

    function tokenURI(uint _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "wrong id");
        return bytes(baseURI).length > 0 ? string(
            abi.encodePacked(
              baseURI,
              Strings.toString(_tokenId),
              ".json"
            )
        ) : "";
    }

    function getPrice() external view returns (uint){
        return price;
    }

    function _startTokenId() internal view virtual override returns (uint) {
        return 1;
    }

    function createTown() external onlyOwner {
        _safeMint(_msgSender(), 1);
    }
}