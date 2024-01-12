// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "./Ownable.sol";

contract HomelessDog is ERC721A, Ownable {
    string  public baseURI;
    uint256 public immutable price = 0.009 ether;
    uint32 public immutable maxSupply = 1000;
    uint32 public immutable perTxMax = 3;

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    constructor()
    ERC721A ("HomelessDog", "HD") {
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

    function mint() public payable callerIsUser{
        require(totalSupply() + 3 <= maxSupply,"sold out");
        require(msg.value >= price,"insufficient");
        _safeMint(msg.sender, 3);
    }

    function withdraw() public onlyOwner {
        uint256 sendAmount = address(this).balance;

        address h = payable(msg.sender);

        bool success;

        (success, ) = h.call{value: sendAmount}("");
        require(success, "Transaction Unsuccessful");
    }
}