// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
import "./Token.sol";

contract Mugs is Token {
    constructor()
        Token("Mugs", "MUGS", 2, 5000, 309, 500, 0.05309 ether, 0 ether, 1734, "", keccak256(""))
    {}
}
