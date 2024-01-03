// SPDX-License-Identifier: MIT

pragma solidity ^ 0.6.6;

import "./ERC20Capped.sol";

contract QERC20 is ERC20Capped {

    constructor () ERC20 ("QFinance Token", "QFI")
        ERC20Capped (1000000000000000000000000) public {
        _mint(msg.sender, 1000000000000000000000000);
    }
}