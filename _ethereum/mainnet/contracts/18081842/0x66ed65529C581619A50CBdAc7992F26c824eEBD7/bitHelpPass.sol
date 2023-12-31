// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721.sol";
import "./Ownable.sol";
import "./ERC721Enumerable.sol";

contract BitHelpMemberCard  is ERC721Enumerable, Ownable{
    uint256 public constant MAX_SUPPLY = 1000;
    uint256 public constant MINT_PRICE = 0.05 ether;

    bool public mintingEnabled;
    bool public _startPublic;
    string private _baseURIextended;
    
    mapping(address => bool) private _whitelist;
    mapping(address => bool) private _hasPurchased;
    mapping(address => uint256) private _nftBalances;

    constructor() ERC721("BitHelp Member Card", "BitHelp Member Card"){
        mintingEnabled = false;
        _startPublic = false;
    }

    function mintEnable(bool _value) external onlyOwner() {
        mintingEnabled = _value;
    }

    function startPublic(bool _value) external onlyOwner() {
        _startPublic = _value;
    }

    function mint() external payable {
        require(mintingEnabled, "mint not enable");
        require(totalSupply() < MAX_SUPPLY, "Maximum supply reached");
        require(!_hasPurchased[msg.sender], "You have already mint an NFT");
        require(msg.value >= MINT_PRICE, "Insufficient funds");

        if(!_startPublic){
            require(_whitelist[msg.sender], "not in whitelist");
        }

        _mint(msg.sender, totalSupply() + 1);
        _hasPurchased[msg.sender] = true;
        _nftBalances[msg.sender]++;
    }

    function batchMint(uint256 mintAmount) external onlyOwner() {
        require(totalSupply() + mintAmount <= MAX_SUPPLY, "Exceeds maximum token supply");
        for (uint256 i = 0; i < mintAmount; ++i) {
            _mint(msg.sender, totalSupply() + 1);
            _nftBalances[msg.sender]++;
        }
    }

    function setBaseURI(string memory baseURI_) external onlyOwner() {
        _baseURIextended = baseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }

    function isWhitelist(address account) external view returns (bool) {
        return _whitelist[account];
    }

    function addWhitelist(address account) external virtual onlyOwner {
        _whitelist[account] = true;
    }

    function batchAddWhitelist(address[] memory array) external virtual onlyOwner {
        for(uint256 i = 0; i < array.length; i++) {
            address addressElement = array[i];
            _whitelist[addressElement] = true;
        } 
    }

    function removeWhitelist(address account) external virtual onlyOwner {
        _whitelist[account] = false;
    }

    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function getBalance(address user) external view returns (uint256) {
        return _nftBalances[user];
    }
}