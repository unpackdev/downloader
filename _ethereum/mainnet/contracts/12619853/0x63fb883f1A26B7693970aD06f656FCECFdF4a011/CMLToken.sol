// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "./ERC20.sol";
import "./IERC721Enumerable.sol";
import "./Token.sol";

/**
 * @title CMLToken contract
 * @dev Extends my ERC20
 */
contract CMLToken is Token {
    constructor(address _nftAddress) Token("Camel Token", "CML", _nftAddress) {}
}
