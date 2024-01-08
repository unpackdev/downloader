// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "./ERC20.sol";
import "./IERC721Enumerable.sol";
import "./Token.sol";

/**
 * @title BAPEToken contract
 * @dev Extends my ERC20
 */
contract BAPEToken is Token {
    constructor(address _nftAddress) Token("Bored Ape Token", "BAPE", _nftAddress) {}
}
