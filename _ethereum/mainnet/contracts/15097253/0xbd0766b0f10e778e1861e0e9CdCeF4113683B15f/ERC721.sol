// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "./Ownable.sol";
import "./ERC721A.sol";

contract ERC721 is ERC721A, Ownable {

    constructor(string memory name_, string memory symbol_) ERC721A(name_, symbol_) Ownable() {}


    function _baseURI() internal override(ERC721A) view virtual returns (string memory) {
        return super._baseURI();
    }

    function _startTokenId() internal override(ERC721A) view virtual returns(uint256) {
        return 1;
    }
}
