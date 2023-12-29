// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "./ERC20.sol";
import "./SafeMath.sol";
import "./AccessControl.sol";
import "./SafeERC20.sol";

import "./IrUSTP.sol";

contract iUSTP is ERC20, AccessControl {
	using SafeERC20 for ERC20;
	using SafeMath for uint256;

	ERC20 public rUSTP;

	constructor(address _admin, ERC20 _rUSTP) ERC20("Wrapped rUSTP", "iUSTP") {
		_setupRole(DEFAULT_ADMIN_ROLE, _admin);
		rUSTP = _rUSTP;
	}

	/**
	 * @dev the exchange rate of iUSTP
	 */
	function pricePerToken() external view returns (uint256) {
		return IrUSTP(address(rUSTP)).getrUSTPAmountByShares(1 ether);
	}

	/**
	 * @dev wrap rUSTP to iUSTP
	 * @param _amount the amount of rUSTP
	 */
	function wrap(uint256 _amount) external {
		// equal shares
		uint256 depositShares = IrUSTP(address(rUSTP)).getSharesByrUSTPAmount(_amount);
		require(depositShares > 0, "can't wrap zero rUSTP");
		rUSTP.safeTransferFrom(msg.sender, address(this), _amount);
		_mint(msg.sender, depositShares);
	}

	/**
	 * @dev unwrap iUSTP to rUSTP
	 * @param _share the share of iUSTP
	 */
	function unwrap(uint256 _share) external {
		uint256 withdrawAmount = IrUSTP(address(rUSTP)).getrUSTPAmountByShares(_share);
		require(withdrawAmount > 0, "can't unwrap zero rUSTP");
		_burn(msg.sender, _share);
		rUSTP.safeTransfer(msg.sender, withdrawAmount);
	}

	/**
	 * @dev wrap all iUSTP to rUSTP
	 */
	function unWrapAll() external {
		uint256 userBalance = balanceOf(msg.sender);
		uint256 withdrawAmount = IrUSTP(address(rUSTP)).getrUSTPAmountByShares(userBalance);
		require(withdrawAmount > 0, "can't wrap zero iUSTP");
		_burn(msg.sender, userBalance);

		rUSTP.safeTransfer(msg.sender, withdrawAmount);
	}

	/**
	 * @dev Allows to recovery any ERC20 token
	 * @param tokenAddress Address of the token to recovery
	 * @param target Address for receive token
	 * @param amountToRecover Amount of collateral to transfer
	 */
	function recoverERC20(
		address tokenAddress,
		address target,
		uint256 amountToRecover
	) external onlyRole(DEFAULT_ADMIN_ROLE) {
		require(tokenAddress != address(rUSTP), "can't recover rUSTP");
		ERC20(tokenAddress).safeTransfer(target, amountToRecover);
	}

	/**
	 * @dev Allows to recovery of rUSTP
	 * @param target Address for receive token
	 */
	function recoverUSTP(address target) external onlyRole(DEFAULT_ADMIN_ROLE) {
		uint256 totalDepositShares = totalSupply();
		uint256 realLockShares = IrUSTP(address(rUSTP)).sharesOf(address(this));
		uint256 recoverAmount = realLockShares - totalDepositShares;
		require(recoverAmount > 0, "no");
		rUSTP.safeTransfer(target, recoverAmount);
	}
}
