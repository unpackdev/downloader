/*
██████████████████████████████████████████████████████████
█░░░░░░░░░░░░░░░░░░█░░░░░░░░░░░░░░█░░░░░░██████████░░░░░░█
█░░▄▀▄▀▄▀▄▀▄▀▄▀▄▀░░█░░▄▀▄▀▄▀▄▀▄▀░░█░░▄▀░░░░░░░░░░██░░▄▀░░█
█░░░░░░░░░░░░▄▀▄▀░░█░░▄▀░░░░░░░░░░█░░▄▀▄▀▄▀▄▀▄▀░░██░░▄▀░░█
█████████░░░░▄▀░░░░█░░▄▀░░█████████░░▄▀░░░░░░▄▀░░██░░▄▀░░█
███████░░░░▄▀░░░░███░░▄▀░░░░░░░░░░█░░▄▀░░██░░▄▀░░██░░▄▀░░█
█████░░░░▄▀░░░░█████░░▄▀▄▀▄▀▄▀▄▀░░█░░▄▀░░██░░▄▀░░██░░▄▀░░█
███░░░░▄▀░░░░███████░░▄▀░░░░░░░░░░█░░▄▀░░██░░▄▀░░██░░▄▀░░█
█░░░░▄▀░░░░█████████░░▄▀░░█████████░░▄▀░░██░░▄▀░░░░░░▄▀░░█
█░░▄▀▄▀░░░░░░░░░░░░█░░▄▀░░░░░░░░░░█░░▄▀░░██░░▄▀▄▀▄▀▄▀▄▀░░█
█░░▄▀▄▀▄▀▄▀▄▀▄▀▄▀░░█░░▄▀▄▀▄▀▄▀▄▀░░█░░▄▀░░██░░░░░░░░░░▄▀░░█
█░░░░░░░░░░░░░░░░░░█░░░░░░░░░░░░░░█░░░░░░██████████░░░░░░█
██████████████████████████████████████████████████████████
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./ERC721A.sol";
import "./Ownable.sol";

contract ZenGoblin is ERC721A, Ownable {

    string public baseURI = "ipfs://QmakfKsZy9NtemmgV6xPFW45NLR1VBzX94ceCn1z4qxCjn/";
    string public constant baseExtension = ".json";
    uint256 public constant MAX_PER_ADDR_FREE = 1;
    uint256 public constant MAX_PER_ADDR = 5;
    uint256 public MAX_MEDITATE_FREE = 1000;
    uint256 public MAX_MEDITATE = 5000;
    uint256 public PRICE = 0.01 ether;
    bool public paused = false;
    bool public gogo = false;

    constructor() ERC721A("ZenGoblin", "ZENGOB") {}

    function meditate(uint256 _amount) external payable {
        require(!paused, "Paused");
        require(gogo, "Not live!");
        require(_amount > 0 && _amount <= MAX_PER_ADDR,"Max per addr exceeded!");
        require(totalSupply() + _amount <= MAX_MEDITATE,"Max supply exceeded!");
        require(_numberMinted(msg.sender) + _amount <= MAX_PER_ADDR,"Max per addr exceeded!");

        if(totalSupply() >= MAX_MEDITATE_FREE) {
            require(msg.value >= PRICE * _amount, "Insufficient funds!");              
        } else {
            uint256 payForCount = _amount;
            if(_numberMinted(msg.sender) == 0) {
                payForCount--;
            }
            require(msg.value >= payForCount * PRICE,"Insufficient funds to mint!");
        }
        _safeMint(_msgSender(), _amount);
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        (bool success, ) = _msgSender().call{value: balance}("");
        require(success, "Failed to send");
    }

    function airdrop(address _to, uint256 _amount) external onlyOwner {
        uint256 total = totalSupply();
        require(total + _amount <= MAX_MEDITATE, "Max supply exceeded!");
        _safeMint(_to, _amount);
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function init() external onlyOwner {
        _safeMint(_msgSender(), 1);
    }

    function pause(bool _state) external onlyOwner {
        paused = _state;
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    function setStart(bool _state) external onlyOwner {
        gogo = _state;
    }

    function setPrice(uint newPrice) external onlyOwner {
        PRICE = newPrice;
    }

    function setFreeCapLimit(uint limit) external onlyOwner {
        MAX_MEDITATE_FREE = limit;
    }

    function reduceSupply(uint newSupply) external onlyOwner {
        MAX_MEDITATE = newSupply;
    }

    function getPrice() external view returns (uint256){
        return PRICE;
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "Token not exist.");
        return bytes(baseURI).length > 0 ? string(
            abi.encodePacked(
              baseURI,
              Strings.toString(_tokenId),
              baseExtension
            )
        ) : "";
    }
}