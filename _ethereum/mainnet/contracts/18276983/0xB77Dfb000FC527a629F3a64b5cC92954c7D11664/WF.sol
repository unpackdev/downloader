//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20.sol";

contract WF is ERC20 {
    constructor() ERC20("World Freedom", "WF") {
        _mint(msg.sender, 1_000_000_000_000 * 10 ** 18); // 1T
    }
}
