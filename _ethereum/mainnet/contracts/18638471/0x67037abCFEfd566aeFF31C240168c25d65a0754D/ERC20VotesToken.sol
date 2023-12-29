// SPDX-License-Identifier: Not Licensed
pragma solidity ^0.8.9;

import "./ERC20.sol";
import "./ERC20Permit.sol";
import "./ERC20Votes.sol";

abstract contract ERC20VotesToken is ERC20, ERC20Permit, ERC20Votes {
    // The following functions are overrides required by Solidity.

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override(ERC20, ERC20Votes) {
        super._afterTokenTransfer(from, to, amount);
    }

    function _mint(
        address to,
        uint256 amount
    ) internal virtual override(ERC20, ERC20Votes) {
        super._mint(to, amount);
    }

    function _burn(
        address account,
        uint256 amount
    ) internal virtual override(ERC20, ERC20Votes) {
        super._burn(account, amount);
    }
}
