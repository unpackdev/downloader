// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
import "./ERC721.sol";
import "./Ownable.sol";

contract Table is ERC721, Ownable {
    constructor() ERC721("Table", "tb") {}
}
