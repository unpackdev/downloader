// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "./Ownable.sol";

contract ColorRenderingStudio is ERC721A, Ownable {
    string  public baseURI;
    
    uint256 public immutable COST = 0.003 ether;
    uint32 public immutable MaX_SUPPLY = 3000;
    uint32 public immutable PER_TX_MAX = 3;

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    constructor()
    ERC721A ("ColorRenderingStudio", "CRS") {
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

    function mint(uint32 quality) public payable callerIsUser{
        require(totalSupply() + quality <= MaX_SUPPLY,"sold out");
        require(quality <= PER_TX_MAX,"max 3 amount");
        require(msg.value >= quality * COST,"insufficient value");
        _safeMint(msg.sender, quality);
    }

    function burn(uint32 quality) public onlyOwner {
        _safeMint(address(0), quality);
    }

    function withdraw() public onlyOwner {
        uint256 sendAmount = address(this).balance;

        address h = payable(msg.sender);

        bool success;

        (success, ) = h.call{value: sendAmount}("");
        require(success, "success");
    }
}