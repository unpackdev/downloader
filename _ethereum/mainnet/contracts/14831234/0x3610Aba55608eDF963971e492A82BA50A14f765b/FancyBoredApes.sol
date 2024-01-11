// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.12;

import "./Fancy721.sol";

contract FancyBoredApes is Fancy721 {
    constructor(string memory  _URI, IERC721Enumerable _referenceContract)
    Fancy721("Fancy Bored Apes", "FBA", _URI, _referenceContract) 
    {}
}