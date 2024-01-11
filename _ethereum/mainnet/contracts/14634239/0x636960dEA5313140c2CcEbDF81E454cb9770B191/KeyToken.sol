// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./SafeMath.sol";
import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./Pausable.sol";
import "./AccessControl.sol";

/// @custom:security-contact info@impact3.io
contract KeyToken is ERC20, ERC20Burnable, Pausable, AccessControl {
	// defensive as not required from pragma ^0.8 onwards
	using SafeMath for uint256;

	// cap maximum supply at 1.1M
	uint256 private _maxSupply = 1111111 * 10**decimals();

	// access control roles
	bytes32 public constant PAUSER_ROLE = keccak256('PAUSER_ROLE');
	bytes32 public constant MINTER_ROLE = keccak256('MINTER_ROLE');

	constructor() ERC20('KeyToken', 'KEY') {
		_grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
		_grantRole(PAUSER_ROLE, msg.sender);
		_grantRole(MINTER_ROLE, msg.sender);
	}

	/** @dev Check if total supply has been surpassed
	 *	@return boolean value
	 */
	function hasReachedCap() public view returns (bool) {
		return (totalSupply() >= _maxSupply);
	}

	/** @dev Pauses the contract
	 */
	function pause() public onlyRole(PAUSER_ROLE) {
		_pause();
	}

	/** @dev Unpauses the contract
	 */
	function unpause() public onlyRole(PAUSER_ROLE) {
		_unpause();
	}

	/** @dev Mint the token
	 *	@param to address
	 *	@param amount in WEI
	 */
	function mint(address to, uint256 amount) public onlyRole(MINTER_ROLE) {
		require(
			totalSupply().add(amount) <= _maxSupply,
			'Maximum supply of tokens already minted.'
		);
		_mint(to, amount);
	}

	/** @dev Called before token transfer
	 *	@param from address
	 *	@param to address
	 *	@param amount number of tokens
	 */
	function _beforeTokenTransfer(
		address from,
		address to,
		uint256 amount
	) internal override whenNotPaused {
		super._beforeTokenTransfer(from, to, amount);
	}
}
