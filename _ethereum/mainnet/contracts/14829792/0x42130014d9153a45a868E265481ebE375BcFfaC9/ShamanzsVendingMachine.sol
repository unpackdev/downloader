// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13 < 0.9.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

contract ShamanzsVendingMachine is Ownable, ReentrancyGuard {

    using Strings for uint256;

    bool public PAUSED = true;
    address public SHAMANZSV2_ADDRESS;
    uint256 public MAX_MINT_AMOUNT = 30;
    uint256 public PRICE = 0.1 ether;
    uint256 public COUNTER = 2524;
    uint256 public MAX_SUPPLY = 4898;

    event shamanzsMinted(address _to, uint256 _qty);

    constructor (address _shamanzs) {
        SHAMANZSV2_ADDRESS = _shamanzs;
    }
    
    function buy(uint256 _mintAmount) external payable nonReentrant {
        require(!PAUSED, "paused");
        require(_mintAmount > 0, "No mint amount set");
        require(msg.value >= PRICE * _mintAmount, "Price not meet");
        require(_mintAmount + COUNTER <= MAX_SUPPLY, "Mint amount exceeded");
        for (uint256 i = 0; i < _mintAmount; i++) {
            require(ERC721(SHAMANZSV2_ADDRESS).ownerOf(COUNTER) == owner(), "Owner doesnt own this shamanz" );
            ERC721(SHAMANZSV2_ADDRESS).transferFrom(owner(), msg.sender, COUNTER);
            COUNTER++;
        }
        emit shamanzsMinted(msg.sender, _mintAmount);
    }

    function setShamanzsAddress(address _shamanzsAddress) public onlyOwner {
        SHAMANZSV2_ADDRESS = _shamanzsAddress;
    }

    function setPrice(uint256 _newPrice) public onlyOwner {
        PRICE = _newPrice;
    }

    function pause(bool _state) public onlyOwner {
        PAUSED = _state;
    }

    function setCounter(uint256 _newCounter) public onlyOwner {
        COUNTER = _newCounter;
    }

    function setSupply(uint256 _supply) public onlyOwner {
        MAX_SUPPLY = _supply;
    }

    function setMaxMintAmount(uint256 _newMaxMintAmount) public onlyOwner {
        MAX_MINT_AMOUNT = _newMaxMintAmount;
    }

    function withdraw() public onlyOwner {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }
}