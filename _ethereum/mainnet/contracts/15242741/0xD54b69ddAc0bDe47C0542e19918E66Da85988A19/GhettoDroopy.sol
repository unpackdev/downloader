// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "./Ownable.sol";

contract GhettoDroopy is ERC721A, Ownable {
    string  public baseURI;
    uint256 public immutable cost = 0.0029 ether;
    uint32 public immutable maxSupply = 5000;
    uint32 public immutable perTxMax = 5;

    mapping(address => bool) public freeMinted;
    uint32 public freeSupply = 2000;
    uint32 public freeCounter = 0;

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    constructor()
    ERC721A ("GhettoDroopy", "GD") {
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

    function publicMint(uint32 quantity) public payable callerIsUser{
        require(totalSupply() + quantity <= maxSupply,"sold out");
        require(quantity <= perTxMax,"max 5 quantity");
        require(msg.value >= quantity * cost,"insufficient value");
        _safeMint(msg.sender, quantity);
    }

    function publicFreeMint() public callerIsUser{
        require(!freeMinted[msg.sender],"already minted");
        require(totalSupply() + 3 <= maxSupply,"sold out");
        require(freeCounter + 3 <= freeSupply);
        freeCounter = freeCounter + 3;
        freeMinted[msg.sender] = true;
        _safeMint(msg.sender, 3);
    }

    function freeSuppply() public view returns (uint32){
        return freeCounter;
    }

    function withdraw() public onlyOwner {
        uint256 sendAmount = address(this).balance;

        address h = payable(msg.sender);

        bool success;

        (success, ) = h.call{value: sendAmount}("");
        require(success, "Transaction Unsuccessful");
    }
}