// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "./ERC721A.sol";

contract GrinderMfers is ERC721A {
    address public immutable owner;

    uint64 public price = 0.02 ether;
    uint64 forOwner = 100;
    uint64 public firstCount = 2000;
    uint64 public secondCount = 7900;
    uint64 maxPerTransaction = 20;

    bool firstFinished = false;
    bool allFinished = false;

    constructor(address _owner) ERC721A("GrinderMfers", "GMF") {
        owner = _owner;
        _safeMint(_owner, forOwner);
    }

    function _baseURI() internal pure override returns (string memory) {
        return "ipfs://QmRWVAhVT7qy2ghownLYUBB31RKcabaDR6WFc1M1AhYVPA/";
    }

    function firstMint(uint256 quantity) external payable {
        require(!firstFinished, "Initial tokens have already been minted!");
        require(quantity <= maxPerTransaction, "Too many tokens requested!");
        require(quantity <= firstCount, "Trying to mint more than available");
        require(msg.value >= price * quantity, "Paying less");

        if (firstCount == quantity) {
            firstFinished = true;
            price = 0.035 ether;
        }

        payable(owner).transfer(msg.value);

        firstCount -= uint64(quantity);
        _safeMint(msg.sender, quantity);
    }

    function secondMint(uint256 quantity) external payable {
        require(firstFinished, "Initial tokens need to be minted!");
        require(!allFinished, "No tokens to mint!");
        require(quantity <= maxPerTransaction, "Too many tokens requested!");
        require(quantity <= secondCount, "Trying to mint more than available");
        require(msg.value >= price * quantity, "Paying less");

        if (secondCount == quantity) {
            allFinished = true;
        }

        payable(owner).transfer(msg.value);

        secondCount -= uint64(quantity);
        _safeMint(msg.sender, quantity);
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        return string(abi.encodePacked(super.tokenURI(tokenId), ".json"));
    }
}