pragma solidity ^0.6.0;

import "./MinterRole.sol";
import "./ERC20.sol";
import "./ERC20Pausable.sol";

/**
 * @title TRC20Mintable
 * @dev TRC20 minting logic.
 */
contract ERC20Mintable is ERC20, ERC20Pausable, MinterRole {

    /**
     * @dev See {ERC20-_beforeTokenTransfer}.
    */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override(ERC20, ERC20Pausable) {
        super._beforeTokenTransfer(from, to, amount);
        ERC20Pausable._beforeTokenTransfer(from, to, amount);
    }
}