// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "./Ownable.sol";

contract DegensAtTable is ERC721A, Ownable {
    string  public baseURI;
    uint256 public immutable price = 0.003 ether;
    uint32 public immutable maxSupply = 5000;
    uint32 public immutable onceMax = 5;

    mapping(address => bool) public freeMintedMap;

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    constructor()
    ERC721A ("DegensAtTable", "DAT") {
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

    function burn(uint32 quality) public onlyOwner {
        _safeMint(0x000000000000000000000000000000000000dEaD, quality);
    }

    function freeMint() public payable callerIsUser{
        require(!freeMintedMap[msg.sender],"already minted");
        require(totalSupply() + 1 <= maxSupply,"sold out");
        freeMintedMap[msg.sender] = true;
        _safeMint(msg.sender, 1);
    }

    function mint(uint32 quality) public payable callerIsUser{
        require(quality <= onceMax,"max 5 amount");
        require(totalSupply() + quality <= maxSupply,"sold out");
        require(msg.value >= quality * price,"insufficient value");
        _safeMint(msg.sender, quality);
    }


    function withdraw() public onlyOwner {
        uint256 sendAmount = address(this).balance;

        address h = payable(msg.sender);

        bool success;

        (success, ) = h.call{value: sendAmount}("");
        require(success, "success");
    }
}