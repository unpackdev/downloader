pragma solidity 0.8.12;
// SPDX-License-Identifier: MIT

import "./ERC20.sol";
import "./draft-ERC20Permit.sol";
import "./ERC20Votes.sol";

contract CrownCapital is ERC20, ERC20Permit, ERC20Votes {

    constructor() ERC20("Crown Capital", "CROWN") ERC20Permit("Crown Capital"){
        _mint(msg.sender, 1e8 * 10**18);
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
