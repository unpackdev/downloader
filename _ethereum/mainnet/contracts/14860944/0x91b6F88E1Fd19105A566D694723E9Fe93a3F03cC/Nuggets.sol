// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "./ERC721A.sol";
import "./Ownable.sol";

contract Nuggets is ERC721A, Ownable {
    uint256 public maxTokenSupply = 5000;
    uint256 public freeAmount = 1000;
    uint256 public constant MAX_MINTS_PER_WALLET = 10;
    uint256 public mintPrice = 0.001 ether;

    string public baseTokenURI;
    bool public mintingIsLive = false;

    constructor(string memory baseURI) ERC721A("Nifty Nuggets", "NUG") {
        setBaseURI(baseURI);
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }
        
    function setBaseURI(string memory _baseTokenURI) public onlyOwner {
        baseTokenURI = _baseTokenURI;
    } 

    function freeMint(uint256 quantity) external callerIsUser {
        require(mintingIsLive, "Minting is not live yet!");
        require(totalSupply() + quantity <= freeAmount, "Reached max free supply");
        require(quantity + _numberMinted(msg.sender) <= MAX_MINTS_PER_WALLET, "Exceeded the limit per wallet");
        _safeMint(msg.sender, quantity);
    }

    function mintNFT(uint256 quantity) external payable {
        require(mintingIsLive, "Minting is not live yet!");
        require(quantity + _numberMinted(msg.sender) <= MAX_MINTS_PER_WALLET, "Exceeded the limit per wallet");
        require(totalSupply() + quantity <= maxTokenSupply, "Not enough tokens left");
        require(msg.value >= (mintPrice * quantity), "Not enough ether sent");
        _safeMint(msg.sender, quantity);
    }

    function toggleMintingState() external onlyOwner {
        mintingIsLive = !mintingIsLive;
    }

    function withdraw() public payable onlyOwner {
        uint balance = address(this).balance;
        require(balance > 0, "No ether left to withdraw");     
        (bool success, ) = (msg.sender).call{value: balance}("");
        require(success, "Transfer failed.");
    }

    function _baseURI() internal view override returns (string memory) {
        return baseTokenURI;
    }

    function setMintPrice(uint256 _mintPrice) public onlyOwner {
        mintPrice = _mintPrice;
    }
}
