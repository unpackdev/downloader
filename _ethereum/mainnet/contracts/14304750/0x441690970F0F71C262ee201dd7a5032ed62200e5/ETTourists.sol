// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "ERC721Tradable.sol";

/**
 * @title Extraterrestrial Tourists
 * ETTourists - a contract for Extraterrestrial Tourists NFT
 */
contract ETTourists is ERC721Tradable {
    uint256 public mintCost = 0.1 ether;
    uint256 public maxMintAmount = 10;
    uint256 public maxTotalSupply = 10000;
    bool public paused;

    constructor(string memory _tokenURIBase, uint256 _totalSupply)
        ERC721Tradable("Extraterrestrial Tourists", "ETT", _tokenURIBase)
    {
        maxTotalSupply = _totalSupply;
    }

    /* minting */
    function mint(address to, uint256 amount) public payable {
        require(amount > 0, "ETT: Min mint amount");
        require(
            totalSupply() + amount <= maxTotalSupply,
            "ETT: Amount exceeds supply"
        );
        uint256 totalCost = amount * mintCost;
        if (msg.sender != owner()) {
            require(!paused, "ETT: Contract paused");
            require(msg.value >= totalCost, "ETT: Not enough funds");
            require(amount <= maxMintAmount, "ETT: Max mint amount");
        }
        require(to != address(0), "ETT: Invalid address");

        for (uint256 i; i < amount; i++) {
            safeMint(to);
        }
    }

    /* owner functions */
    function setMintCost(uint256 value) public onlyOwner {
        mintCost = value;
    }

    function setPaused(bool value) public onlyOwner {
        paused = value;
    }

    function withdraw() public payable onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }
}
