// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IOwnable.sol";
import "./IERC20AltApprove.sol";
import "./IERC20Burnable.sol";
import "./IERC20Metadata.sol";

/**
 * @dev Interface of the Fermion token.
 */
interface IFermion is IOwnable, IERC20AltApprove, IERC20Metadata, IERC20Burnable
{
	/**
	* @dev Mints `amount` tokens to `account`.
	*
	* Emits a {Transfer} event with `from` set to the zero address.
	*/
	function mint(address to, uint256 amount) external;
}