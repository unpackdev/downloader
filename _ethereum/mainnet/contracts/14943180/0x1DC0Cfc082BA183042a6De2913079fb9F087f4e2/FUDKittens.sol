// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Ownable.sol";

//     FUD KITTENS
//      ,_     _,
//      |\\___//|
//      |=6   6=|
//      \=._Y_.=/
//      /       \  ((
//      |       |   ))
//     /| |   | |\_//
//     \| |._.| |/-`
//      '"'   '"'
//     DONT MINT ME

contract FUDKittens is Ownable, ERC721A {
    uint256 public maxSupply = 4444;
    bool public paused = true;
    uint256 cost = 0.0022 ether;
    string public baseURI;

    // For checking minted per wallet
    mapping(address => uint) internal freeMints;
    mapping(address => uint) internal losersWhoPay;

    constructor() ERC721A('FUD Kittens', 'FUDK') {}

    // HurRy mint 2 FREE B4 They RUN OUT!!! - WAGMI
    function mintFree(uint256 _mintAmount) public payable {
        require(tx.origin == _msgSender(), "Only EOA");
        require(!paused, "Contract paused");
        require(totalSupply() + _mintAmount <= maxSupply, "No enough mints left.");

        // ADDS CHECK FOR 2 PER WALLET
        require(freeMints[msg.sender] <= 2, "You have already minted!");
        
        freeMints[msg.sender] += _mintAmount;
        _safeMint(msg.sender, _mintAmount);
    }

    // Losers who want to pay for more, 5 per wallet 0.0022 ETH each - NGMI
    function mintPaid(uint256 _mintAmount) public payable {
        require(tx.origin == _msgSender(), "Only EOA");
        require(!paused, "Contract paused");
        require(_mintAmount > 0);
        require(totalSupply() + _mintAmount <= maxSupply, "No enough mints left.");

        // ADDS CHECK FOR 5 PER WALLET
        require(losersWhoPay[msg.sender] + _mintAmount <= 5, "Max mint exceeded!");
        require(msg.value >= cost * _mintAmount, "Not enough ETH. 0.0022 per.");
        
        losersWhoPay[msg.sender] += _mintAmount;
        _safeMint(msg.sender, _mintAmount);
    }
    
    function pause(bool _state) public onlyOwner {
        paused = _state;
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function withdraw() public payable onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }
}