pragma solidity ^0.8.11;

// SPDX-License-Identifier: MIT
/// @title SoulDay Collection
/// @author El Cid Rodrigo
/// @dev El Cid Rodrigo

// We are artists, developers, and artificial intelligence scientists.
// The contents herein outline the terms for the SoulDay collection:
// There is a maximum token count of 25,000.
// Galeria Rodrigo, LLC will reserve 250 tokens in this contract for company investments.
// The Ethereum block-chain is public and outside of Galeria Rodrigo's direct sphere of influence.
// All artwork within the SoulDay collection; Copyright© 2022, Galeria Rodrigo, LLC, All rights reserved.
// Learn more about our SoulDay collection at galeriarodrigo.com and soulday.io.

import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract SoulDay is ERC721Enumerable, Ownable {
    using Address for address;
    using Strings for uint256;

    // Starting and stopping sale and presale
    bool public saleActive = false;
    bool public presaleActive = false;

    // Reserved
    uint256 public reserved = 250;

    // Price of each token
    uint256 public price = 0.08 ether;

    // Maximum tokens
    uint256 constant MAX_SUPPLY = 25000;

    uint256 public constant MAX_PER_ADDRESS_PRESALE = 10;
    uint256 public constant MAX_PER_ADDRESS_PUBLIC = 25;

    // whitelist for presale
    mapping(address => bool) public whitelisted;

    // Team addresses for withdrawals
    address public Account1 = 0x62b8518586b6A4a25166F6c472aAF9395d17582a;
    address public Account2 = 0x68929bafe059bB00CE5Cc8693A7044AE18cd7fD1;
    address public Account3 = 0x6b7541962b8212F11801Eaa5e1E2DF05B7c84d08;
    address public Archive = 0x44aA64A2fB3C9C2bbE66E9a69be18b1909aEbF2F;


    // Base URI
    string private _baseURIextended = "ipfs://";
    constructor() ERC721("SoulDay", "SDY") {}

    // Which address owns which tokens
    function tokensOfOwner(address addr) public view returns(uint256[] memory) {
        uint256 tokenCount = balanceOf(addr);
        uint256[] memory tokensId = new uint256[](tokenCount);
        for(uint256 i; i < tokenCount; i++){
            tokensId[i] = tokenOfOwnerByIndex(addr, i);
        }
        return tokensId;
    }

    // mint
    function mint(uint256 _amount) public payable {
        uint256 supply = totalSupply();
        if (presaleActive) {
            require(whitelisted[msg.sender] == true, "Not presale member");
            require( _amount > 0 && _amount <= MAX_PER_ADDRESS_PRESALE,    "Can only mint between 1 and 10 tokens at once" );
            require( supply + _amount <= MAX_SUPPLY, "Can't mint more than max supply" );
            require(balanceOf(msg.sender) + _amount <= MAX_PER_ADDRESS_PRESALE, "Can only mint up to 10 tokens per address");
            require( msg.value == price * _amount,   "Wrong amount of ETH sent" );
            for(uint256 i; i < _amount; i++){
                _safeMint( msg.sender, supply + i + 1 ); // Token id starts from 1
            }
        } else {
            if (saleActive) {
                require( _amount > 0 && _amount <= MAX_PER_ADDRESS_PUBLIC,    "Can only mint between 1 and 25 tokens at once" );
                require( supply + _amount <= MAX_SUPPLY, "Can't mint more than max supply" );
                require(balanceOf(msg.sender) + _amount <= MAX_PER_ADDRESS_PUBLIC, "Can only mint up to 25 tokens per address");
                require( msg.value == price * _amount,   "Wrong amount of ETH sent" );
                for(uint256 i; i < _amount; i++){
                    _safeMint( msg.sender, supply + i + 1); // Token id starts from 1
                }
            } else {
                require( presaleActive,                  "Presale is not active" );
                require( saleActive,                     "Sale is not active" );
            }
        }
    }

    // Admin minting function to reserve tokens
    function mintReserved(uint256 _amount) public  {
        require( msg.sender == Archive, "Don't have permission to mint" );
        // Limited to a publicly set amount
        require( _amount <= reserved, "Can't reserve more than set amount" );
        reserved -= _amount;
        uint256 supply = totalSupply();
        for(uint256 i; i < _amount; i++){
            _safeMint( msg.sender, supply + i + 1); // Token id starts from 1
        }
    }

    // Start and Stop pre sale
    function setPresaleActive(bool val) public onlyOwner {
        presaleActive = val;
    }

    // Start and Stop sale
    function setSaleActive(bool val) public onlyOwner {
        saleActive = val;
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        _baseURIextended = baseURI_;
    }
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }


    // Set a different price in E
    function setPrice(uint256 newPrice) public onlyOwner {
        price = newPrice;
    }

    // add user's address to whitelist for presale
    function addWhitelistUser(address[] memory _user) public onlyOwner {
        for(uint256 idx = 0; idx < _user.length; idx++) {
            require(whitelisted[_user[idx]] == false, "previously set");
            whitelisted[_user[idx]] = true;
        }
    }

    // remove user's address to whitelist for presale
    function removeWhitelistUser(address[] memory _user) public onlyOwner {
        for(uint256 idx = 0; idx < _user.length; idx++) {
            require(whitelisted[_user[idx]] == true, "does not exist");
            whitelisted[_user[idx]] = false;
        }
    }


    // withdraw all amount from contract
    function withdrawAll() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "There is no balance");
        uint256 percent = balance / 100;
        _withdraw(Account1, percent * 100/3);
        _withdraw(Account2, percent * 100/3);
        _withdraw(Account3, percent * 100/3);
    }

    function _withdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Transfer failed.");
    }
}