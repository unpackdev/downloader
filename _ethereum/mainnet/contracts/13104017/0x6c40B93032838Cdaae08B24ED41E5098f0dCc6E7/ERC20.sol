// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/* INHERITANCE IMPORTS */

import "./Context.sol";
import "./IERC20Events.sol";

/* STORAGE */

import "./ERC20Storage.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20Events, ERC20Storage {
    
    /* INITIALIZE METHOD */

    /**
     * @dev Sets the values for {name}, {symbol}, {decimals}, and {inital minted supply}.
     * All of these values are immutable: they can only be set once during
     * initialization. This means it is the developer's responsibility to
     * only call this function in the initialize function of the base contract context.
     */
    function _initalizeERC20(string calldata setName, string calldata setSymbol, uint8 setDecimals, uint256 initialSupply) internal {
        x.erc20.named = setName;
        x.erc20.symboled = setSymbol;
        x.erc20.decimaled = setDecimals;
        _mint_(_msgSender(), initialSupply);
    }

    /* GETTER METHODS */

    /**
     * @dev Returns the name of the token.
     */
    function _name() internal view returns (string memory) {
        return x.erc20.named;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function _symbol() internal view returns (string memory) {
        return x.erc20.symboled;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function _decimals() internal view returns (uint8) {
        return x.erc20.decimaled;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function _totalSupply() internal view returns (uint256) {
        return x.erc20.total;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function _balanceOf(address account) internal view returns (uint256) {
        return x.erc20.balances[account];
    }

    /* STATE CHANGE METHODS */

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _transfer_(sender, recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function _allowance(address owner, address spender) internal view returns (uint256) {
        return _allowance_(owner, spender);
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function _approve(address spender, uint256 amount) internal returns (bool) {
        _approve_(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function _transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (bool) {
        _transfer_(sender, recipient, amount);

        uint256 currentAllowance = x.erc20.allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20._transferFrom: AMOUNT_EXCEEDS_ALLOWANCE");
        unchecked {
            _approve_(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function _increaseAllowance(address spender, uint256 addedValue) internal returns (bool) {
        _approve_(_msgSender(), spender, x.erc20.allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function _decreaseAllowance(address spender, uint256 subtractedValue) internal returns (bool) {
        uint256 currentAllowance = x.erc20.allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20._decreaseAllowance: DECREASE_BELOW_ZERO");
        unchecked {
            _approve_(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function _burn(uint256 amount) internal returns (bool) {
        _burn_(_msgSender(), amount);
        return true;
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
    function _burnFrom(address account, uint256 amount) internal returns (bool) {
        uint256 currentAllowance = _allowance_(account, _msgSender());
        require(
            currentAllowance >= amount,
            "ERC20._burnFrom: AMOUNT_EXCEEDS_ALLOWANCE"
        );
        unchecked {
            _approve_(account, _msgSender(), currentAllowance - amount);
        }
        _burn_(account, amount);
        return true;
    }

    /* PRIVATE LOGIC METHODS */

    function _allowance_(address owner, address spender) private view returns (uint256) {
        return x.erc20.allowances[owner][spender];
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer_(
        address sender,
        address recipient,
        uint256 amount
    ) private {
        require(sender != address(0), "ERC20._transfer_: SENDER_ZERO_ADDRESS");
        require(recipient != address(0), "ERC20._transfer_: RECIPIENT_ZERO_ADDRESS");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = x.erc20.balances[sender];
        require(senderBalance >= amount, "ERC20._transfer_: AMOUNT_EXCEEDS_BALANCE");
        unchecked {
            x.erc20.balances[sender] = senderBalance - amount;
        }
        x.erc20.balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint_(address account, uint256 amount) private {
        require(account != address(0), "ERC20._mint_: ACCOUNT_ZERO_ADDRESS");

        _beforeTokenTransfer(address(0), account, amount);

        x.erc20.total += amount;
        x.erc20.balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn_(address account, uint256 amount) private {
        require(account != address(0), "ERC20._burn_: ACCOUNT_ZERO_ADDRESS");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = x.erc20.balances[account];
        require(accountBalance >= amount, "ERC20._burn_: AMOUNT_EXCEEDS_BALANCE");
        unchecked {
            x.erc20.balances[account] = accountBalance - amount;
        }
        x.erc20.total -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve_(
        address owner,
        address spender,
        uint256 amount
    ) private {
        require(owner != address(0), "ERC20._approve_: OWNER_ZERO_ADDRESS");
        require(spender != address(0), "ERC20._approve_: SPENDER_ZERO_ADDRESS");

        x.erc20.allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /* INTERNAL HOOKS */

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal {}
}