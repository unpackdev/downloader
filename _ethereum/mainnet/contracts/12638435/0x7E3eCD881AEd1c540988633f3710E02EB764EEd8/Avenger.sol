// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC20.sol";
import "./ERC20Pausable.sol";

contract Avenger is Ownable, ERC20Pausable {
    constructor(address wallet) ERC20("Avenger", "AVG") {
        _mint(wallet, (10 * (10**9)) * (10**18));
        transferOwnership(wallet);
    }

    function setPause(bool value) public onlyOwner {
        if (value) {
            _pause();
        } else {
            _unpause();
        }
    }

    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        uint256 currentAllowance = allowance(account, _msgSender());
        require(
            currentAllowance >= amount,
            "ERC20: burn amount exceeds allowance"
        );
        _approve(account, _msgSender(), currentAllowance - amount);
        _burn(account, amount);
    }
}
