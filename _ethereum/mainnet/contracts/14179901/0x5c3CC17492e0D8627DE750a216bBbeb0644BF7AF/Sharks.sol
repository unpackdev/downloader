//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// @title:  Sharks
// @desc:   154 beautiful shark NFTs
// @artist: https://www.instagram.com/euanart/
// @author: https://twitter.com/giaset
// @url:    https://nft.beashark.photos/

import "./GenericMint.sol";

contract Sharks is GenericMint {
    uint256 public constant MAX_PER_WALLET_AND_MINT = 3;
    uint256 public constant MAX_SUPPLY = 154;
    uint256 public constant TOKEN_PRICE = 0.1 ether;

    constructor(string memory baseTokenURI)
        GenericMint(
            "Sharks",
            "SHRK",
            baseTokenURI,
            MAX_PER_WALLET_AND_MINT,
            MAX_SUPPLY,
            TOKEN_PRICE
        )
    {}
}
