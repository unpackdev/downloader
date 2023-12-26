// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import "./Base721.sol";

contract HackataoContract is Base721 {
    constructor(uint96 _royalty, string memory _name, string memory _symbol) Base721(_royalty, _name, _symbol) {}
}
