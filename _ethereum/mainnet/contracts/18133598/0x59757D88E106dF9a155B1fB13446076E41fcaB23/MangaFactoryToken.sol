// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./ERC20.sol";

contract MangaFactoryToken is ERC20 {
    constructor() ERC20("MangaFactoryToken", "MFT") {
        _mint(msg.sender, 100_000_000 * 1e18);
    }

    function burn(uint256 value) external {
        _burn(msg.sender, value);
    }
}