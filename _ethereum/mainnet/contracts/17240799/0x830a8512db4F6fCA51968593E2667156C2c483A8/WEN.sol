// SPDX-License-Identifier: MIT
/*
 __       __  ________  __    __ 
|  \  _  |  \|        \|  \  |  \
| $$ / \ | $$| $$$$$$$$| $$\ | $$
| $$/  $\| $$| $$__    | $$$\| $$
| $$  $$$\ $$| $$  \   | $$$$\ $$
| $$ $$\$$\$$| $$$$$   | $$\$$ $$
| $$$$  \$$$$| $$_____ | $$ \$$$$
| $$$    \$$$| $$     \| $$  \$$$
 \$$      \$$ \$$$$$$$$ \$$   \$$
*/

pragma solidity ^0.8.19;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./draft-ERC20Permit.sol";
import "./ERC20Votes.sol";
import "./Ownable.sol";

contract WEN is ERC20, ERC20Burnable, ERC20Permit, ERC20Votes, Ownable {

    constructor() ERC20("WEN Token", "WEN") ERC20Permit("WEN Token") {
        _mint(msg.sender, 420000000000 * 10 ** decimals());
    }

    function _afterTokenTransfer(address from, address to, uint256 amount)
        internal
        override(ERC20, ERC20Votes)
    {
        super._afterTokenTransfer(from, to, amount);
    }

    function _mint(address to, uint256 amount)
        internal
        override(ERC20, ERC20Votes)
    {
        super._mint(to, amount);
    }

    function _burn(address account, uint256 amount)
        internal
        override(ERC20, ERC20Votes)
    {
        super._burn(account, amount);
    }
}