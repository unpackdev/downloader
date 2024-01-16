// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./IERC20Burnable.sol";
import "./Context.sol";

/**
* @notice Extension of {ERC20} that allows token holders to destroy both their own
* tokens and those that they have an allowance for, in a way that can be
* recognized off-chain (via event analysis).
*/
contract ERC20Burnable is Context, ERC20, IERC20Burnable
{
	/**
	* @notice Sets the values for {name} and {symbol}.
	*
	* The default value of {decimals} is 18. To select a different value for
	* {decimals} you should overload it.
	*
	* All two of these values are immutable: they can only be set once during
	* construction.
	*/
	constructor(string memory tokenName, string memory tokenSymbol) ERC20(tokenName, tokenSymbol)
	{} // solhint-disable-line no-empty-blocks

	/**
	* @notice Destroys `amount` tokens from the caller.
	*
	* See {ERC20-_burn}.
	*/
	function burn(uint256 amount) public virtual override
	{
		_burn(_msgSender(), amount);
	}

	/**
	* @notice Destroys `amount` tokens from `account`, deducting from the caller's allowance.
	*
	* See {ERC20-_burn} and {ERC20-allowance}.
	*
	* Requirements:
	* - the caller must have allowance for `account`'s tokens of at least `amount`.
	*/
	function burnFrom(address account, uint256 amount) public virtual override
	{
		_spendAllowance(account, _msgSender(), amount);
		_burn(account, amount);
	}
}
