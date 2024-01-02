// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./Ownable.sol";

contract ERC20TokenOwnable is ERC20, Ownable {
    uint256 constant internal _version = 2023112717579823;

    constructor(string memory name_, string memory symbol_, address receiver_, uint256 totalSupply_) ERC20(name_, symbol_) {
        _mint(receiver_, totalSupply_);
    } 
}

