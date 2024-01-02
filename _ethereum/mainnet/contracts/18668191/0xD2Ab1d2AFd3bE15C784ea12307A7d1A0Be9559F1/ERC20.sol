// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import "./ERC20.sol";

contract SUPToken is ERC20 {
    constructor() ERC20("Super Transaction Token", "SUP") {
        _mint(msg.sender, 97637 * 10**8);
    }

    function decimals() public view virtual override returns (uint8) {
        return 8;
    }
}