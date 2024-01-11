// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./BaseIntellaX.sol";
import "./IBurnable.sol";

/**
 * Intella X token contract
 *
 * implements ERC20 burnable
 * supports openzeppelin's AccessControl and ERC20Permit extension by extending BaseIntellaX
 * admin - the address holds default admin permission and pauser role
 * initialHolder - the address hold pre-minted supply of the token
 */
contract IntellaX is BaseIntellaX, IBurnable {
    string constant NAME = "Intella X";
    string constant SYMBOL = "IX";

    constructor(address admin, address initialHolder)
        BaseIntellaX(admin, NAME, SYMBOL)
    {
        _mint(initialHolder, 2_000_000_000 ether);
    }

    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) external override {
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
    function burnFrom(address account, uint256 amount) external override {
        _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
    }
}
