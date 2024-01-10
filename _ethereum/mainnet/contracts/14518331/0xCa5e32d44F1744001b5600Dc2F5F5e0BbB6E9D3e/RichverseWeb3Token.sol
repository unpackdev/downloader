// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./ERC20.sol";

contract RichverseWeb3Token is ERC20 {
    constructor() ERC20("RichverseWeb3Token", "RIV") {
        _mint(msg.sender, 2e11 * 10 ** decimals());
    }
}