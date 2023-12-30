// SPDX-License-Identifier: MIT

pragma solidity >=0.6.8;

import "./ERC20.sol";

contract HegicToken is ERC20 {
    constructor() public ERC20("hegic test token", "HEGIC") {
        _mint(msg.sender, 1000 * 1000 * 10**18);
    }
}
