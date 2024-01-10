// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Toucans2.sol";

contract Toucans3 is Toucans2 {
    string private __baseURI;

    function setBaseURI(string calldata base)
    external
        onlyOwner()
    {
        __baseURI = base;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        string memory baseURI = __baseURI;
        return bytes(baseURI).length > 0  ? baseURI : super._baseURI();
    }
}
