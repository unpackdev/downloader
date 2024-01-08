// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./ERC721Base.sol";

contract Displays is ERC721Base {

    string constant private _token = 'MOIRE';
    string constant private _desc = 'On Chain Moire Displays';
    uint256 constant private _price = 60000000000000000; // .06
    uint256 constant private _maxTotal = 3333;
    uint256 constant private _maxMint = 10;
    constructor() ERC721Base(_desc, _token, _price, _maxTotal, _maxMint) {
    }

 }
