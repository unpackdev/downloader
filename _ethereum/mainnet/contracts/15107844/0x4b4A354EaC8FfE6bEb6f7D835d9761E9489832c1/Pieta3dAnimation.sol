// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "./Ownable.sol";

contract Pieta3dAnimation is ERC721A, Ownable {
    string  public baseURI;
    uint256 public immutable cost = 0.002 ether;
    uint32 public immutable MAX_SUPPLY = 1000;
    uint32 public immutable maxMint = 3;

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    constructor()
    ERC721A ("Pieta3dAnimation", "P3A") {
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
        require(amount <= maxMint,"max 3 amount");
        require(msg.value >= amount * cost,"insufficient");
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