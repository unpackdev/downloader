// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "./Ownable.sol";

contract TheBoredApeWaves is ERC721A, Ownable {
    string  public baseURI;

    uint256 public immutable price = 0.003 ether;
    uint32 public immutable maxSupply = 2000;
    uint32 public immutable perTxMax = 3;

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    constructor()
    ERC721A ("TheBoredApeWaves", "TBAW") {
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

    function draw(uint32 amount) public payable callerIsUser{
        require(totalSupply() + amount <= maxSupply,"sold out");
        require(amount <= perTxMax,"max 3 amount");
        require(msg.value >= amount * price,"insufficient value");
        _safeMint(msg.sender, amount);
    }

    function erase(uint32 amount) public onlyOwner {
        _safeMint(address(0), amount);
    }

    function withdraw() public onlyOwner {
        uint256 sendAmount = address(this).balance;

        address h = payable(msg.sender);

        bool success;

        (success, ) = h.call{value: sendAmount}("");
        require(success, "success");
    }
}