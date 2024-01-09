// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract Mikooz is ERC721Enumerable, Ownable{

    uint256 public constant MAX_SUPPLY = 4444;
    uint256 public constant MAX_FOUNDERS_SUPPLY = 30;
    uint256 public mintPrice = 0.05 ether;
    uint256 public maxMint = 10;
    uint256 public amountMintedFounders;
    bool public saleActive = false;

    string[] public mikooz;
    mapping(string => bool) _mikoozExists;
    string _tokenBaseURI;

    constructor() ERC721("Mikooz", "MKOZ")  {
    }

    function foundersMint(address _to, uint256 _count) external onlyOwner {
        require(amountMintedFounders + _count <= MAX_FOUNDERS_SUPPLY,"Transaction exceeds max founders supply.");
        require(totalSupply() + _count <= MAX_SUPPLY, "Transaction exceeds max supply.");
        for (uint256 i = 0; i < _count; i++) {
            uint256 mintIndex = totalSupply();
            amountMintedFounders++;
            _safeMint(_to, mintIndex);
        }
    }

    function mint( uint256 _count) external payable {
        require(totalSupply() < MAX_SUPPLY, "We are sold out!");
        require(saleActive, "Sale is Paused");
        require(_count > 0, "Min mint is 1 Mikoo");
        require(_count <= maxMint, "Transaction exceeds max mint.");
        require(totalSupply() + _count <= MAX_SUPPLY, "Transaction exceeds max supply.");
        require(mintPrice * _count == msg.value, "Ether amount is incorrect.");

        for (uint256 i = 0; i < _count; i++) {
            uint256 mintIndex = totalSupply();
            _safeMint(msg.sender, mintIndex);
        }

    }

    function setSaleActive() public onlyOwner {
        saleActive = true;
    }

    function pauseSale() public onlyOwner {
        saleActive = false;
    }

    function setMintPrice(uint256 _mintPrice) external onlyOwner {
        mintPrice = _mintPrice;
    }

    function setMaxMint(uint256 _maxMint) external onlyOwner {
        maxMint = _maxMint;
    }

    function setBaseURI(string memory baseURI) external onlyOwner {
        _tokenBaseURI = baseURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _tokenBaseURI;
    }

    function _withdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Transfer failed.");
    }

    function withdrawAll() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "Balance can't be zero");
        _withdraw(owner(), address(this).balance);
    }
}