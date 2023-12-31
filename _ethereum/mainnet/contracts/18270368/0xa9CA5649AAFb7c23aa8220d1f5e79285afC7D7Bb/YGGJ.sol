// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import "./ERC20.sol";

contract YGGJ is ERC20 {
    constructor() public ERC20("YGG Japan Token", "YGGJ") {
        _mint(msg.sender, 1000000000 * 10 ** decimals());
    }
}
