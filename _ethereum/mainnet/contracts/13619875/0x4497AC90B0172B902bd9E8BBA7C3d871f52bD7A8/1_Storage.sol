// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC20.sol";

import "./AccessControlEnumerable.sol";
import "./Ownable.sol";

/**
This can be used for off-chain functionality on Ethereum.
Conversion of 
 */
contract Treasury is AccessControlEnumerable, Ownable {
	/**
    @notice OWNER ROLE - Only Owner can add admins.
    The role is only used to assign roles to ot.to..t.t
	her roles.
    Ownable is used for onlyOwner and single owner og the contract.
    */
	bytes32 public constant OWNER_ROLE = keccak256('OWNER_ROLE');

	/**
    @notice ADMIN ROLE
    Admin can call transfer to Owner.
    */
	bytes32 public constant ADMIN_ROLE = keccak256('ADMIN_ROLE');

	/**
    @notice - onlyAdmin
    */
	modifier onlyAdmin() {
		require(hasRole(ADMIN_ROLE, _msgSender()), 'Treasury: Not admin.');
		_;
	}

	event Deposit(address indexed sender, address indexed recipient, uint256 amount);
	event Withdraw(address indexed sender, address indexed recipient, uint256 amount);

	event Transfer(address indexed sender, address indexed recipient, uint256 amount);

	event Approval(address indexed owner, address indexed spender, uint256 amount);

	IERC20 public token;
	uint8 public decimals;
	string public name;
	string public symbol;

	constructor(address _owner, address tokenAddr) {
		transferOwnership(_owner);

		token = IERC20(tokenAddr);

		_setupRole(ADMIN_ROLE, _owner);
		_setupRole(OWNER_ROLE, _owner);

		_setRoleAdmin(OWNER_ROLE, OWNER_ROLE);
		_setRoleAdmin(ADMIN_ROLE, OWNER_ROLE);

		decimals = 18;
		name = 'Treasury';
		symbol = 'Treasury';
	}

	/**
    @notice Deposit to Treasury. 
    @dev This is a function added specifically for  Token.
    The newBalance - oldBalance makes sure that 5% burn of  token is kept into account.
    This ensures the Transfer emit is correct.
    */
	function deposit(uint256 amount) external {
		uint256 oldBalance = token.balanceOf(address(this));

		token.transferFrom(_msgSender(), address(this), amount);

		uint256 newBalance = token.balanceOf(address(this));
		emit Transfer(_msgSender(), address(this), newBalance - oldBalance);
		emit Deposit(_msgSender(), address(this), newBalance - oldBalance);
	}

	/**
    @notice Withdraw from Treasury. 
    @dev This is a function added specifically for  Token.
    The newBalance - oldBalance makes sure that 5% burn of  token is kept into account.
    This ensures the Transfer emit is correct.
    */
	function withdraw(uint256 amount) external  {
		uint256 oldBalance = token.balanceOf(address(this));
		uint256 allowance = token.allowance(address(this), _msgSender());
		require(allowance >= amount, 'Treasury: Amount exceeds allowance.');

		token.approve(_msgSender(), allowance - amount);
		token.transfer(_msgSender(), amount);

		uint256 newBalance = token.balanceOf(address(this));
		emit Transfer(address(this), _msgSender(), oldBalance - newBalance);
		emit Withdraw(address(this), _msgSender(), oldBalance - newBalance);
	}

	function approve(address withdrawer, uint256 amount) external onlyAdmin {
		token.approve(withdrawer, amount);
		emit Approval(address(this), withdrawer, amount);
	}
}
