// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "./ERC721.sol";
import "./SafeMath.sol";
import "./AccessControl.sol";

contract TERC721 is ERC721, AccessControl {
    uint256 id = 0;

    constructor(string memory name, string memory symbol)
        public
        ERC721(name, symbol)
    {}

    function mint(address to) public returns (uint256) {
        id++;
        _mint(to, id);
    }
}
