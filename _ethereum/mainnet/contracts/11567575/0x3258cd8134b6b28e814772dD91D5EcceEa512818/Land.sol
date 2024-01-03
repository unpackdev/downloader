// SPDX-License-Identifier: MIT

import "./ERC777.sol";

pragma solidity ^0.6.9;

contract Land is ERC777 {
    constructor () public ERC777("Land", "LAND", new address[](0)) {
        _mint(msg.sender, 57706752 * (10 ** 18), "", "");
    }
}