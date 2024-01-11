/*
Free Mint Project! This is trainer contract. Soon there will be monster contract.
████████████████████████████████████████████████████████████████████████
█▄─▀█▄─▄█▄─▄▄─█─▄▄─█▄─▀█▄─▄███─▄─▄─█▄─▄▄▀██▀▄─██▄─▄█▄─▀█▄─▄█▄─▄▄─█▄─▄▄▀█
██─█▄▀─███─▄█▀█─██─██─█▄▀─██████─████─▄─▄██─▀─███─███─█▄▀─███─▄█▀██─▄─▄█
▀▄▄▄▀▀▄▄▀▄▄▄▄▄▀▄▄▄▄▀▄▄▄▀▀▄▄▀▀▀▀▄▄▄▀▀▄▄▀▄▄▀▄▄▀▄▄▀▄▄▄▀▄▄▄▀▀▄▄▀▄▄▄▄▄▀▄▄▀▄▄▀
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./ERC721A.sol";
import "./Ownable.sol";

contract NeonTrainer is ERC721A, Ownable {
    bool public pause = false;
    bool public startSale = false;
    string public constant uriSuffix = ".json";
    string public baseURI = "ipfs://QmQVXxgqm8xP9PRXRWvLMrxQtFN3PVy28GgunmhxpUuLT1/";
    uint public maxFree = 2;
    uint public maxPerTransaction = 10;
    uint public collectionSize = 6666;
    uint public price = 0.0035 ether;

    constructor() ERC721A("Neon Trainer", "NTTN") {}

    function _startTokenId() internal view virtual override returns (uint) {
        return 1;
    }

    function getPrice() external view returns (uint){
        return price;
    }

    function withdraw() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    function ownerBuy() external onlyOwner {
        _safeMint(_msgSender(), 1);
    }

    function stop(bool value) external onlyOwner {
        pause = value;
    }

    function publicSale(bool trigger) external onlyOwner {
        startSale = trigger;
    }

    function changePrice(uint _price) external onlyOwner {
        price = _price;
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    function tokenURI(uint _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "Invalid id.");
        return bytes(baseURI).length > 0 ? string(
            abi.encodePacked(
              baseURI,
              Strings.toString(_tokenId),
              uriSuffix
            )
        ) : "";
    }

    function freeMint(uint val) external payable {
        require(!pause, "public sale is paused");
        require(startSale, "public sale is closed");
        require(collectionSize >= totalSupply() + val, "Sold out");
        require(tx.origin == msg.sender, "Must be sender");
        require(val > 0 && val <= maxPerTransaction,"Exceed quantity allowed per trx");
        
      if(_numberMinted(msg.sender) >= maxFree){
            require(msg.value >= val * price, "Insufficient funds");
        }else{
            uint num = _numberMinted(msg.sender) + val;
            if(num > maxFree){
                require(msg.value >= (num - maxFree) * price , "Insufficient funds");
            }   
        }
        _safeMint(_msgSender(), val);
    }
}