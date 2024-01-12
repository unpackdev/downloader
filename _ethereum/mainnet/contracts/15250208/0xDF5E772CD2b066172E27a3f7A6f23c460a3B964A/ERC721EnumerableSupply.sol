// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.2;

import "./ERC721Enumerable.sol";

/// @title Existance Check to ERC721Enumerable
/// @author Metacrypt (https://www.metacrypt.org/)
abstract contract ERC721EnumerableSupply is ERC721Enumerable {
    function exists(uint256 tokenId) public view returns (bool) {
        return _exists(tokenId);
    }
}
