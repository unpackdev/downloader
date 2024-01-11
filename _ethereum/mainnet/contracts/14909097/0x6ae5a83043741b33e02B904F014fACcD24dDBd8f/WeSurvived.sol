// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "./Ownable.sol";

contract WeSurvived is ERC721A, Ownable {
    uint256 public immutable price = 0.003 ether;
    uint32 public immutable maxMint = 10;
    uint32 public immutable MAX_SUPPLY = 5000;
    bool public started = false;
    mapping(address => uint) public addressClaimed;
    string  public baseURI;

    constructor()
    ERC721A ("WeSurvived", "WS") {
    }

    function _baseURI() internal view override(ERC721A) returns (string memory) {
        return baseURI;
    }

    function _startTokenId() internal view virtual override(ERC721A) returns (uint256) {
        return 0;
    }

    function setURI(string memory uri) public onlyOwner {
        baseURI = uri;
    }

    function mint(uint32 amount) public payable {
        require(tx.origin == msg.sender, "pls don't use contract call");
        require(started,"not yet started");
        require(totalSupply() + amount <= MAX_SUPPLY,"sold out");
        require(amount <= maxMint,"max 10 amount");
        require(msg.value >= amount * price,"insufficient");
        _safeMint(msg.sender, amount);
    }

    function freeClaim() public {
        require(tx.origin == msg.sender, "pls don't use contract call");
        require(started,"not yet started");
        require(totalSupply() + 1 <= MAX_SUPPLY,"sold out");
        require(addressClaimed[_msgSender()] < 1, "You have already received your token");
        addressClaimed[_msgSender()] += 1;
        _safeMint(msg.sender, 1);
    }

    function enableMint(bool mintStarted) external onlyOwner {
      started = mintStarted;
   }

    function withdraw() public onlyOwner {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success, "failed");
    }
}