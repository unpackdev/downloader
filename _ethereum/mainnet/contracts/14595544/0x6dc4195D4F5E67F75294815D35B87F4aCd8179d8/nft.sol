// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "ERC721A.sol";
import "./Ownable.sol";

/*
• ▌ ▄ ·.              ▐ ▄ ▄▄▄▄· ▪  ▄▄▄  ·▄▄▄▄  .▄▄ · 
·██ ▐███▪▪     ▪     •█▌▐█▐█ ▀█▪██ ▀▄ █·██▪ ██ ▐█ ▀. 
▐█ ▌▐▌▐█· ▄█▀▄  ▄█▀▄ ▐█▐▐▌▐█▀▀█▄▐█·▐▀▀▄ ▐█· ▐█▌▄▀▀▀█▄
██ ██▌▐█▌▐█▌.▐▌▐█▌.▐▌██▐█▌██▄▪▐█▐█▌▐█•█▌██. ██ ▐█▄▪▐█
▀▀  █▪▀▀▀ ▀█▄▀▪ ▀█▄▀▪▀▀ █▪·▀▀▀▀ ▀▀▀.▀  ▀▀▀▀▀▀•  ▀▀▀▀  proof.xyz
*/

contract Moonbirds is ERC721A, Ownable {
    uint256 MAX_SUPPLY = 10000;
    uint256 public PRICE = 2.5 ether;
    
    bool public presale = false;
    bool public saleIsActive = true;

    mapping(address => uint8) private _allowList;

    string public baseURI = "https://collective.proof.xyz/collection/moonbirds/meta/";

    constructor() ERC721A("Moonbirds", "MB") {}

    function mint(uint8 quantity) external payable
    {
        require(msg.sender == tx.origin, "No transaction from smart contracts!");
        require(!presale, "Still in pre-sale");
        require(saleIsActive, "Sale must be active to mint");
        require(quantity > 0 && quantity <= 1, "Max per transaction reached");
        require(totalSupply() + quantity <= MAX_SUPPLY, "Exceeds max supply");
        require(msg.value >= PRICE * quantity, "Not enough ETH for transaction");

        _safeMint(msg.sender, quantity);
    }

    function mintRaffle(uint8 quantity) external payable
    {
        require(msg.sender == tx.origin, "No transaction from smart contracts!");
        require(quantity <= _allowList[msg.sender], "Exceeded max available to purchase");
        require(saleIsActive, "Sale must be active to mint");
        require(totalSupply() + quantity <= MAX_SUPPLY, "Exceeds max supply");
        require(msg.value >= PRICE * quantity, "Not enough ETH for transaction");
        
        _allowList[msg.sender] -= quantity;
        _safeMint(msg.sender, quantity);
    }

    function ownerMint(address[] calldata addresses) external onlyOwner
    {
        require(totalSupply() + 1 <= MAX_SUPPLY, "Exceeds max supply");
        for (uint256 i = 0; i < addresses.length; i++) {
            _safeMint(addresses[i], 1, "");
        }
    }

    function setFreeAllowList(address[] calldata addresses, uint8 numAllowedToMint) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            _allowList[addresses[i]] = numAllowedToMint;
        }
    }

    function freeAvailableToMint(address addr) external view returns (uint8) {
        return _allowList[addr];
    }

    function setPrice(uint256 _price) external onlyOwner 
    {
        PRICE = _price;
    }

    function flipSaleState() external onlyOwner
    {
        saleIsActive = !saleIsActive;
    }

    function flipPresaleState() external onlyOwner
    {
        presale = !presale;
    }

    function withdraw() external payable onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

}