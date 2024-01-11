// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "./ERC721AQueryable.sol";
import "./ERC721.sol";

abstract contract ERC721Queryable is ERC721, ERC721AQueryable {

    function _baseURI() internal override(ERC721, ERC721A) view virtual returns (string memory) {
        return super._baseURI();
    }

    function _startTokenId() internal override(ERC721, ERC721A) view virtual returns(uint256) {
        return super._startTokenId();
    }
}
