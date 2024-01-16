// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "./Ownable.sol";

abstract contract First9Lives {
    function balanceOf(address owner) external virtual view returns (uint256 balance);
}

contract The9Lives is ERC721A, Ownable {
    string public baseURI = "ipfs://QmPpL6NCgPXsf86rjt3LTeCd6omN9ENL2N6tQD5s87ZsTf/";

    uint256 public immutable mintPrice = 0.0025 ether;
    uint32 public immutable maxSupply = 699;
    uint32 public immutable perTxLimit = 2;
    mapping(address => bool) public mintedMap;
    First9Lives private f9l;

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }
    
    constructor()
    ERC721A ("9Lives by 0met", "9Lives") {f9l=First9Lives(0x2Bb5C9Eb8B779bEd32c04C6a2b6F1972684C0738);
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

    function holderMint(uint32 amount) public payable callerIsUser{
        require(totalSupply() + amount <= 222,"no more");
        require(amount <= perTxLimit,"max 2 amount");
        require(f9l.balanceOf(msg.sender) >= amount);
        require(!mintedMap[msg.sender]);
        mintedMap[msg.sender] = true;
        _safeMint(msg.sender, amount);
    }

    function publicMint(uint32 amount) public payable callerIsUser{
        require(totalSupply() + amount <= maxSupply,"sold out");
        require(amount <= perTxLimit,"max 2 amount");
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