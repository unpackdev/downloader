// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./SimpleNFTCollection.sol";

contract FckinHeads is SimpleNFTCollection {
    constructor()
        SimpleNFTCollection(
            "F'ckin Heads", // Name
            "FCKH", // Symbol
            "ipfs://QmdhnCb9RB8RETHQYFfqBdtHFnHfHiJfPEwZGq6tSmZEAS", // Not revealed URI
            0.0025 ether, // Cost to mint
            5000, // Max supply
            10, // Max mint amount per tx
            0x4BfdAFfB172F79BCD20382d263b7745F0E2420d1 // Contract owner
        )
    {}
}
