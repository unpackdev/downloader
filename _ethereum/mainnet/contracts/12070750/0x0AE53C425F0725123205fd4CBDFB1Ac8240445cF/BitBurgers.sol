// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.2;

import "./ERC721.sol";

contract BitBurgers is ERC721 {
    uint constant SALE_START = 1616763600;
    uint constant SALE_END = 1625400000;
    uint constant HIGHEST_BURGER_ID = 9999;
    uint constant BURGER_COST = 5000000000000000; // 0.005 ETH
    string constant URI_PREFIX = "ipfs://QmUkvJmPrLQ4KZUygf5ojip6QkNCBs35CpZbgQ4dRVzVnB/";
    address constant FUND_MANAGER = 0xB2F94BB15Fe02382bbFe80cD50c6614cf35b3adB;

    bool insideBuyBurgerBatch = false;

    constructor() ERC721("BitBurgers", "BRGR") {
    }

    modifier duringSalePeriod {
        require(SALE_START < block.timestamp, "Sale didn't start yet");
        require(block.timestamp < SALE_END, "Sale ended");
        _;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return URI_PREFIX;
    }

    function mintBurger(address owner, uint256 tokenId) external {
        require(insideBuyBurgerBatch, "function can only called by buyBurgerBatch");
        require(tokenId <= HIGHEST_BURGER_ID, "tokenId out of range");
        _mint(owner, tokenId);
    }

    function buyBurger(uint256 tokenId) public payable duringSalePeriod {
        require(tokenId <= HIGHEST_BURGER_ID, "tokenId out of range");
        require(msg.value == BURGER_COST, "you need to send the exact cost of 1 bitburger");
        
        _mint(msg.sender, tokenId);
    }

    function buyBurgerBatch(uint256[] memory tokenIds) public payable duringSalePeriod {
        require(msg.value >= BURGER_COST * tokenIds.length, "not enough funds to cover the cost of all BitBurgers");

        uint256 remaining_balance = msg.value;

        insideBuyBurgerBatch = true;
        for (uint i = 0; i < tokenIds.length; i++) {
            try this.mintBurger(msg.sender, tokenIds[i]) {
                remaining_balance -= BURGER_COST;
            } catch {}
        }
        insideBuyBurgerBatch = false;

        if (remaining_balance>0) {
            payable(msg.sender).transfer(remaining_balance);
        }
    }

    function withdrawFunds(address payable wallet) public {
        require(msg.sender == FUND_MANAGER, "only the fund manager can withdraw");
        wallet.transfer(address(this).balance);
    }
}
