// SPDX-License-Identifier: MIT

//** HODL Finance DAO Token */
pragma solidity 0.8.17;

import "./ERC20Burnable.sol";

contract HFDToken is ERC20Burnable {
    constructor() ERC20("HODL Finance DAO Token", "HFD") {
        _mint(msg.sender, 1_000_000_000 * 10 ** decimals());
    }
}