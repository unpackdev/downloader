// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";

contract MoonFlower is ERC721A, Ownable {
    string  public baseURI;
    uint256 public immutable mintPrice = 0.002 ether;
    uint32 public immutable maxSupply = 3333;
    uint32 public immutable perTxMax = 5;

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    constructor()
    ERC721A ("MoonFlower", "MF") {
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
        require(totalSupply() + amount <= maxSupply,"sold out");
        require(amount <= perTxMax,"max 5 amount");
        require(msg.value >= amount * mintPrice,"insufficient");
        _safeMint(msg.sender, amount);
    }

    function devMint() public onlyOwner {
       _safeMint(msg.sender, 100);
    }

    function withdraw() public onlyOwner {
        uint256 sendAmount = address(this).balance;

        address h = payable(msg.sender);

        bool success;

        (success, ) = h.call{value: sendAmount}("");
        require(success, "Transaction Unsuccessful");
    }
}