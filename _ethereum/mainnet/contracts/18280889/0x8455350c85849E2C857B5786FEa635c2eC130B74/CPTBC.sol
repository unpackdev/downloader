// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

/**
 *
 *                                 888
 *      .d8888b 88888b.     888    88888b.   .d8888b
 *     d88P"    888 "88b    888    888 "88b d88P"
 *     888      888  888 888888888 888  888 888
 *     Y88b.    888 d88P    888    888 d88P Y88b.
 *      "Y8888P 88888P"     888    88888P"   "Y8888P
 *              888
 *
 *
 * @title Children pretend to be children
 * @author akibe
 */

import "./Token.sol";

contract CPTBC is Token {
    constructor(string memory baseTokenURI) Token('Children pretend to be children', 'CPTBC', baseTokenURI, 1000) {}
}
