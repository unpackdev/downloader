// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./ERC20.sol";
import "./ERC20Burnable.sol";

contract ShibraEth is ERC20, ERC20Burnable {
    constructor() ERC20("ShibraEth", "SHE") {
        _mint(msg.sender, 100000000 * 10 ** decimals());
    }
}
