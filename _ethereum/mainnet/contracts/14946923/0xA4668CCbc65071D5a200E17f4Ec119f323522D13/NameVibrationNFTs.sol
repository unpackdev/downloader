// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./Ownable.sol";
import "./ERC721A.sol";

contract NameVibrationNFTs is ERC721A, Ownable {
    string private baseURI;

    bool public started = false;
    uint256 public constant MAX_SUPPLY = 8888;
    uint256 public MAX_FREE_SUPPLY = 500;
    uint256 public MAX_MINT = 10;
    uint256 public PRICE = 0.02 ether;

    mapping(address => uint) public addressClaimed;

    constructor() ERC721A("Name Vibration NFTs", "NameVibrationNFTs") {}

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function freeMint(uint256 numberOfNfts) external {
        require(started, "The minting has not yet started.");
        require(numberOfNfts <= MAX_MINT, "The requested number is more than the possible value.");
        require(addressClaimed[_msgSender()] < MAX_MINT, "You have already received your max NFTs.");
        require(addressClaimed[_msgSender()] + numberOfNfts <= MAX_MINT, "The requested number is more than the possible value.");
        require(totalSupply() < MAX_FREE_SUPPLY, "All possible free NFTs have been minted.");
        require(totalSupply() + numberOfNfts <= MAX_FREE_SUPPLY, "There are not enough free mintable NFTs.");
        require(totalSupply() < MAX_SUPPLY, "All NFTs have been minted.");
        require(totalSupply() + numberOfNfts <= MAX_SUPPLY, "There are not enough mintable NFTs.");

        addressClaimed[_msgSender()] += numberOfNfts;
        _safeMint(msg.sender, numberOfNfts);
    }

    function mint(uint256 numberOfNfts) external payable {
        require(started, "The minting has not yet started.");
        require(numberOfNfts <= MAX_MINT, "The requested number is more than the possible value.");
        require(addressClaimed[_msgSender()] < MAX_MINT, "You have already received your max NFTs.");
        require(addressClaimed[_msgSender()] + numberOfNfts <= MAX_MINT, "The requested number is more than the possible value.");
        require(totalSupply() < MAX_SUPPLY, "All NFTs have been minted.");
        require(totalSupply() + numberOfNfts <= MAX_SUPPLY, "There are not enough mintable NFTs.");
        require(msg.value == numberOfNfts * PRICE, "Please send the exact amount.");

        addressClaimed[_msgSender()] += numberOfNfts;
        _safeMint(msg.sender, numberOfNfts);
    }

    function claim(address[] memory _addresses, uint256 numberOfNfts) external onlyOwner {
        for (uint i = 0; i < _addresses.length; i++) {
            _safeMint(_addresses[i], numberOfNfts);
            addressClaimed[_addresses[i]] += numberOfNfts;
        }
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function enableMint(bool mintStarted) external onlyOwner {
        started = mintStarted;
    }

    function setMaxMint(uint256 maxMint) external onlyOwner {
        MAX_MINT = maxMint;
    }

    function setMaxFreeSupply(uint256 maxFreeSupply) external onlyOwner {
        MAX_FREE_SUPPLY = maxFreeSupply;
    }

    function setPrice(uint256 newPrice) public onlyOwner {
        PRICE = newPrice;
    }
    
    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
}