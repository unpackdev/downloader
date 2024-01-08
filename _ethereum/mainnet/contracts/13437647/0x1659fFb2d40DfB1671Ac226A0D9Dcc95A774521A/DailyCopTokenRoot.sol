// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./ERC20.sol";
import "./IERC20.sol";
import "./IMintableERC20.sol";
import "./AccessControlEnumerable.sol";
import "./Ownable.sol";
import "./draft-ERC20Permit.sol";
import "./Multicall.sol";

contract DailyCopTokenRoot is
	ERC20Permit,
	IMintableERC20,
	AccessControlEnumerable,
	Ownable,
	Multicall
{
	// Roles
	bytes32 public constant PREDICATE_ROLE = keccak256("PREDICATE_ROLE");

	modifier notThisAddress(address account) {
		require(
			account != address(this),
			"Address can not be the token contract's address"
		);
		_;
	}

	constructor(address owner, address predicateProxy)
		ERC20("Daily COP", "DLYCOP")
		ERC20Permit("DailyCopToken")
	{
		// Minting on layer 1 root chain can only be done by the bridge's predicate proxy
		_setupRole(PREDICATE_ROLE, predicateProxy);
		// Take the owner role from the deployer and pass it to the specified owner
		transferOwnership(owner);
	}

	/**
	 * @dev See {IMintableERC20-mint}.
	 */
	function mint(address user, uint256 amount)
		external
		override
		onlyRole(PREDICATE_ROLE)
	{
		_mint(user, amount);
	}

	/**
	 * @dev See {IERC20-transfer}.
	 *
	 * Requirements:
	 *
	 * - `recipient` cannot be the zero address.
	 * - the caller must have a balance of at least `amount`.
	 */
	function transfer(address recipient, uint256 amount)
		public
		virtual
		override(ERC20, IERC20)
		notThisAddress(recipient)
		returns (bool)
	{
		return super.transfer(recipient, amount);
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
	function transferFrom(
		address sender,
		address recipient,
		uint256 amount
	)
		public
		virtual
		override(ERC20, IERC20)
		notThisAddress(recipient)
		returns (bool)
	{
		return super.transferFrom(sender, recipient, amount);
	}

	/**
	 * @notice called when admin wants to unlock erc20 tokens owned by the contract
	 * @param _tokenAddress the address of the tokens to unlock
	 * @param _to the address to send the tokens to
	 * @param _amount amount of tokens to unlock
	 */
	function transferAnyERC20(
		address _tokenAddress,
		address _to,
		uint256 _amount
	) public onlyOwner {
		IERC20(_tokenAddress).transfer(_to, _amount);
	}
}
