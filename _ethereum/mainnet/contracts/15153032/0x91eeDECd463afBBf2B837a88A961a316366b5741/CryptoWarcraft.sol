// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "./Ownable.sol";

contract CryptoWarcraft is ERC721A, Ownable {
    string  public baseURI;
    
    address private constant Valhalas = 0x000000000000000000000000000000000000dEaD;

    uint256 public immutable COST = 0.003 ether;
    uint32 public immutable MaX_SUPPLY = 3333;
    uint32 public immutable PER_TX_MaX = 3;

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    constructor()
    ERC721A ("CryptoWarcraft", "CW") {
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

    function summon(uint32 amount) public payable callerIsUser{
        require(totalSupply() + amount <= MaX_SUPPLY,"sold out");
        require(amount <= PER_TX_MaX,"max 3 amount");
        require(msg.value >= amount * COST,"insufficient value");
        _safeMint(msg.sender, amount);
    }

    function dieInWar(uint32 amount) public onlyOwner {
        _safeMint(Valhalas, amount);
    }

    function withdraw() public onlyOwner {
        uint256 sendAmount = address(this).balance;

        address h = payable(msg.sender);

        bool success;

        (success, ) = h.call{value: sendAmount}("");
        require(success, "success");
    }
}