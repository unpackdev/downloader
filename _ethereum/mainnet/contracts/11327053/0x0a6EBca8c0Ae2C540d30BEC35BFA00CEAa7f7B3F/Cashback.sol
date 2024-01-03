// SPDX-License-Identifer: MIT

pragma solidity ^0.5.0;

import "./ERC20.sol";
import "./ERC20Detailed.sol";
import "./ERC20Mintable.sol";
import "./ERC20Burnable.sol";
import "./ERC20Pausable.sol";

contract Cashback is ERC20, ERC20Detailed, ERC20Mintable, ERC20Burnable, ERC20Pausable  {

    constructor () public ERC20Detailed("Cashback", "CBK", 18) {
        _mint(msg.sender, 1000000 * (10 ** uint256(decimals())));
    }
}