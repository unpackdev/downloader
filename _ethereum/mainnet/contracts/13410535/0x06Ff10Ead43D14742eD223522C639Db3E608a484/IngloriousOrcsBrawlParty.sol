// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./ERC721Enumerable.sol";

contract IngloriousOrcsBrawlParty is ERC721Enumerable, Ownable {
    using Address for address;

    uint256 public constant MAX_SUPPLY = 10000;
    uint256 private _mintPrice = 0.08 ether;

    bool private _isSaleActive = false;
    bool private _isPrivateSaleActive = false;

    // baseURI
    string private _baseTokenURI;

    mapping(address => uint256) whitelisted;

    constructor(string memory baseURI) ERC721("IngloriousOrcsBrawlParty", "IOBP") {
        setBaseURI(baseURI);
    }

    function setPrice(uint256 newPrice) public onlyOwner() {
        _mintPrice = newPrice;
    }

    function getPrice() public view returns (uint256) {
        return _mintPrice;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    function flipSaleState() public onlyOwner {
        _isSaleActive = !_isSaleActive;
    }

    function isSaleLive() public view returns (bool) {
        return _isSaleActive;
    }

    function isPrivateSaleLive() public view returns (bool) {
        return _isPrivateSaleActive;
    }

    function flipPrivateSaleState() public onlyOwner {
        _isPrivateSaleActive = !_isPrivateSaleActive;
    }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function isWhitelisted(address addr) public view returns (uint256) {
        return whitelisted[addr];
    }

    function addToWhitelist(address[] memory addresses, uint256 count) public onlyOwner() {
        for (uint i = 0; i < addresses.length; ++i) {
            whitelisted[addresses[i]] = count;
        }
    }

    function removeFromWhitelist(address[] memory addresses) public onlyOwner() {
        for (uint i = 0; i < addresses.length; ++i) {
            whitelisted[addresses[i]] = 0;
        }
    }

    function reserve(uint256 num) public onlyOwner() {
        uint256 supply = totalSupply();

        require((supply + num) <= MAX_SUPPLY, "Exceeds maximum supply");
        for (uint256 i = 0; i < num; i++) {
            _safeMint(msg.sender, supply + i);
        }
    }

    function mint(uint256 num) public payable {
        uint256 supply = totalSupply();

        require(_isSaleActive, "Sale paused");
        require(num < 11, "You can mint a maximum of 10 per transaction");
        require((supply + num) <= MAX_SUPPLY, "Exceeds maximum supply");
        require(msg.value >= _mintPrice * num, "Ether sent is not correct");

        for (uint256 i = 0; i < num; i++) {
            _safeMint(msg.sender, supply + i);
        }
    }

    function mintPrivateSale(uint256 num) public payable {
        uint256 supply = totalSupply();
        uint256 remaining = whitelisted[msg.sender];

        require(_isPrivateSaleActive, "Private Sale paused");
        require(num <= remaining, "You are not whitelisted or you don't have any more NFT to mint");
        require((supply + num) <= MAX_SUPPLY, "Exceeds maximum supply");
        require(msg.value >= _mintPrice * num, "Ether sent is not correct");

        whitelisted[msg.sender] = remaining - num;

        for (uint256 i = 0; i < num; i++) {
            _safeMint(msg.sender, supply + i);
        }
    }
}