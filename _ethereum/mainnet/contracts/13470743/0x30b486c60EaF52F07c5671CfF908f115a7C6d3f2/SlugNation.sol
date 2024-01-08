// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./ERC721Enumerable.sol";

contract SlugNation is ERC721Enumerable, Ownable {
    
    uint256 public constant maxSupply = 5000;
    uint256 private _price = 0.05 ether;
    uint256 private _psMintLimit = 8;
    uint256 private _mintLimit = 20;
    uint256 private _reserved = 50;
    uint256 private _reserveClaimed = 0;
    uint256 private _freeTokens = 1000;
    uint256 private _freeTokensClaimed = 0;

    bool private _saleStarted = false;
    bool private _preSaleStarted = false;
    string private baseURI;

    mapping(address => bool) private _preSaleEligible;
    mapping(address => uint256) private _totalClaimed;
    mapping(address => bool) private _freeClaimed;

    // Withdraw Addresses
    address t1 = 0xb75A5f0bB19D0A6C14b0Fd988E8893e7F8397342;
    address t2 = 0x9F5a7984E2854DdcD810D8A8621baE805034E61C;


    constructor() ERC721("SlugNation", "SN") {}

    modifier saleIsOpen() {
        require(_saleStarted, "The public sale has not yet started.");
        _;
    }

    modifier preSaleIsOpen() {
        require(_preSaleStarted, "The presale has not yet started.");
        _;
    }

    function preSaleMint(uint256 _numberOfTokens) public payable preSaleIsOpen {
        uint256 supply = totalSupply();
        require(_preSaleEligible[msg.sender], "You are not eligible for the presale");
        require(supply < maxSupply - _reserved, "All Slugger's have been minted.");
        require(_totalClaimed[msg.sender] < _psMintLimit, "You have reached the max allowed for presales.");
        require(_numberOfTokens > 0, "You must mint at least one Slugger.");
        require(_totalClaimed[msg.sender] + _numberOfTokens <= _psMintLimit, "Purchase exceeds the max allowed for presale. Please select a lower quantity.");
        require(supply + _numberOfTokens <= maxSupply - _reserved, "Not enough Slugger's left to mint. Please select a lower quantity.");
        require(_price * _numberOfTokens <= msg.value, "Transaction value is incorrect!");

        _totalClaimed[msg.sender] += _numberOfTokens;
        uint256 tokensToMint = _numberOfTokens;

        if (!_freeClaimed[msg.sender]) {
            tokensToMint += 1;
            _freeTokensClaimed += 1;
            _freeClaimed[msg.sender] = true;
        }

        for (uint256 i; i < tokensToMint; i++) {
            _safeMint(msg.sender, supply + i);
        }  
    }

    function mint(uint256 _numberOfTokens) public payable saleIsOpen {
        uint256 supply = totalSupply();
        require(supply < maxSupply - _reserved, "All Slugger's have been minted.");
        require(_numberOfTokens > 0, "You must mint at least one Slugger.");
        require(_numberOfTokens <= _mintLimit, "You cannot mint so many Slugger's at once!");
        require(supply + _numberOfTokens <= maxSupply - _reserved, "Not enough Slugger's left to mint. Please select a lower quantity.");
        require(_price * _numberOfTokens <= msg.value, "Transaction value is incorrect!");

        uint256 tokensToMint = _numberOfTokens;
        uint256 freeTokensLeft = _freeTokens - _freeTokensClaimed;

        if (freeTokensLeft > 0) {
            if (freeTokensLeft >= tokensToMint) {
                _freeTokensClaimed += tokensToMint;
                tokensToMint = tokensToMint * 2;
            } else {
                _freeTokensClaimed += freeTokensLeft;
                tokensToMint = tokensToMint + freeTokensLeft;
            }
        }

        for (uint256 i; i < tokensToMint; i++) {
            _safeMint(msg.sender, supply + i);
        }  
    }

    function getPrice() public view returns(uint256) {
        return _price;
    }

    function setPrice(uint256 _newPrice) external onlyOwner {
        _price = _newPrice;
    }

    function getFreeTokens() public view returns(uint256) {
        return _freeTokens;
    }

    function setFreeTokens(uint256 _value) external onlyOwner {
        _freeTokens = _value;
    }

    function getFreeTokensClaimed() public view returns(uint256) {
        return _freeTokensClaimed;
    }

    function startSale() external onlyOwner {
        _saleStarted = !_saleStarted;
    }

    function saleStarted() public view returns(bool) {
        return _saleStarted;
    }

    function startPreSale() external onlyOwner {
        _preSaleStarted = !_preSaleStarted;
    }

    function preSaleStarted() public view returns(bool) {
        return _preSaleStarted;
    }

    function setBaseURI(string memory _URI) external onlyOwner {
        baseURI = _URI;
    }

    function getBaseURI() external view onlyOwner returns(string memory) {
        return baseURI;
    }

    function _baseURI() internal view virtual override returns(string memory) {
        return baseURI;
    }

    function addToPresale(address[] calldata addresses) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            require(addresses[i] != address(0), "Cannot add null address");

            _preSaleEligible[addresses[i]] = true;
            _totalClaimed[addresses[i]] = 0;
        }
    }

    function checkPresaleEligibility(address addr) external view returns (bool) {
        return _preSaleEligible[addr];
    }

    function claimReserved(address _receiver, uint256 _amountToClaim) external onlyOwner {
        uint256 supply = totalSupply();
        require(_reserveClaimed < _reserved, "All reserved tokens have been claimed.");
        require(_amountToClaim <= _reserved - _reserveClaimed, "Amount claimed exceeds the number of reserved tokens left.");
        require(supply + _amountToClaim <= maxSupply, "Cannot claim more than the maximum supply of tokens.");
        require(_receiver != address(0), "Cannot add null address");

        for (uint256 i; i < _amountToClaim; i++) {
            _safeMint(_receiver, supply + i);
        }

        _reserveClaimed += _amountToClaim;
    }

    function getReservedLeft() public view returns (uint256) {
        return _reserved - _reserveClaimed;
    }

    function walletOfOwner(address _owner) public view returns(uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for(uint256 i; i < tokenCount; i++){
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }

    function withdrawAll() public payable onlyOwner {
        uint256 _share = address(this).balance / 2;
        require(payable(t1).send(_share));
        require(payable(t2).send(_share));
    }
}