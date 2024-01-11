// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "./Ownable.sol";

contract SaudisGirls is ERC721A, Ownable {
    string  public baseURI;
    uint32 public immutable MAX_SUPPLY = 3000;
    uint32 public immutable maxMint = 2;

    mapping(address => bool) public freeMinted;

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    constructor()
    ERC721A ("SaudisGirls", "SG") {
    }

    function _baseURI() internal view override(ERC721A) returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory uri) public onlyOwner {
        baseURI = uri;
    }

    function _startTokenId() internal view virtual override(ERC721A) returns (uint256) {
        return 0;
    }

    function mint(uint32 amount) public payable callerIsUser{
        require(totalSupply() + amount <= MAX_SUPPLY,"sold out");
        require(amount <= maxMint,"max 2 amount");
        require(!freeMinted[msg.sender],"already minted");
        freeMinted[msg.sender] = true;
        _safeMint(msg.sender, amount);
    }
    
    function devMint(uint32 amount) public onlyOwner {
        _safeMint(msg.sender, amount);
    }

    function withdraw() public onlyOwner {
        uint256 sendAmount = address(this).balance;

        address h = payable(msg.sender);

        bool success;

        (success, ) = h.call{value: sendAmount}("");
        require(success, "Transaction Unsuccessful");
    }
}