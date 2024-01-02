// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./Ownable.sol";

contract LUCIA is ERC20, Ownable {
    constructor() ERC20("LUCIA", "LUCIA") Ownable() {
        _mint(msg.sender, 100000000000000 * 10 ** 18);
    }
}