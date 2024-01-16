// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "./Ownable.sol";

contract TheBanished is ERC721A, Ownable {
    string public baseURI = "ipfs/QmZHApuPNBTXE6xc6p5zhLGDQTEX7XvDA6yQKzHeeLVaQr";

    uint256 public immutable mintPrice = 0.001 ether;
    uint32 public immutable maxSupply = 1111;
    uint32 public immutable perTxLimit = 10;

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    constructor()
    ERC721A ("TheBanished", "TB") {
    }

    function _baseURI() internal view override(ERC721A) returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory uri) public onlyOwner {
        baseURI = uri;
    }

    function _startTokenId() internal view virtual override(ERC721A) returns (uint256) {
        return 1;
    }

    function publicMint(uint32 amount) public payable callerIsUser{
        require(totalSupply() + amount <= maxSupply,"sold out");
        require(amount <= perTxLimit,"max 10 amount");
        require(msg.value >= amount * mintPrice,"insufficient value");
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