// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "./Context.sol";
import "./AccessControl.sol";
import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./ERC20Pausable.sol";


/**
 * @dev {ERC20} token, including:
 *
 * - ability for holder to burn (destroy) their tokens
 * - a minter role that allows for token minting (creation)
 * - a pauser role that allows to stop all token transfers
 *
 * This contract uses {AccessControl} to lock permissioned functions using the
 * different roles - head to its documentation for details.
 *
 * The account that deployes the contract will be granted the minter and pauser
 * roles, as well as the default admin role, which let it grant both minter
 * and pauser roles to other accounts
 *
 * This contract take care of name, symbol and decimals (default 18). This params
 * should be hardcoded.
 *
 * Should be also capped, with maximum supply 40million of tokens. 
 * 40 * 10^6 * 10*18 (decimals) = 40 * 10^24
 */
contract GHOST is Context, AccessControl, ERC20Burnable, ERC20Pausable {
	
	using SafeMath for uint256;
	uint256 private _cap;

	bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
	bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");


	/**
	 * @dev Grants `DEFAULT_ADMIN_ROLE`, `MINTER_ROLE` and `PAUSER_ROLE` to the
	 * account that deploys the contract.
	 *
	 * See {ERC20-constructor}
	 *
	 * Sets name, symbol and cap (in wei) for the token hardcoded.
	 */
	constructor() ERC20("GHOSTMV", "GMV") {
		_setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

		_setupRole(MINTER_ROLE, _msgSender());
		_setupRole(PAUSER_ROLE, _msgSender());

		_cap = 40000000000000000000000000;
	}


	/**
	 * @return Cap on the token's total supply.
	 */
	function cap() public view returns (uint256) {
		return _cap;
	}


	/**
	 * @dev Creates `amount` new tokens for `to`.
	 *
	 * See {ERC20-_mint}
	 *
	 * Requirements:
	 *
	 * - the caller must have the `MINTER_ROLE`
	 *
	 * @param to Address where new tokens should be minted.
	 * @param amount Amount of tokens to be minted.
	 */
	function mint(address to, uint256 amount) public virtual returns (bool) {
		require(hasRole(MINTER_ROLE, _msgSender()), "MinterRole: caller does not have the Minter role");
		_mint(to, amount);
		return true;
	}


	/**
	 * @dev Pause all token transfers.
	 *
	 * See {ERC20Pausable} and {Pausable-pause}.
	 *
	 * Requirements:
	 *
	 * - the caller must have the `PAUSER_ROLE`.
	 */
	function pause() public virtual {
		require(hasRole(PAUSER_ROLE, _msgSender()), "PauserRole: caller does not have the Pauser role");
		_pause();
	}


	/**
	 * @dev Unpause all token transfers.
	 *
	 * See {ERC20Pausable} and {Pausable_unpause}.
	 *
	 * Requirements:
	 *
	 * - the caller must have the `PAUSER_ROLE`.
	 */
	function unpause() public virtual {
		require(hasRole(PAUSER_ROLE, _msgSender()), "PauserRole: caller does not have the Pauser role");
		_unpause();
	}

	/**
	 * @dev See {ERC20-_beforeTokenTransfer}.
	 *
	 * Requirements:
	 *
	 * - minted tokens must not cause the total supply to go over the cap.
	 */
	function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override(ERC20, ERC20Pausable) {
		super._beforeTokenTransfer(from, to, amount);

		if (from == address(0)) { // When minting tokens
			require(totalSupply().add(amount) <= _cap, "ERC20Capped: cap exceed");
		}
	}

}
