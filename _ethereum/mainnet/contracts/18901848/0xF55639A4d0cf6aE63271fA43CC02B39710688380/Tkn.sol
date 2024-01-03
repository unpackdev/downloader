// SPDX-License-Identifier: MIT
pragma solidity >=0.8.22;

import "./ERC20.sol";
import "./IERC20.sol";

contract Cookie3 is ERC20 {
    constructor() ERC20("Cookie3", "COOKIE") {
        uint256 amount = 100000000 * 10 ** 18;
        _mint(msg.sender, amount);
    }
}
