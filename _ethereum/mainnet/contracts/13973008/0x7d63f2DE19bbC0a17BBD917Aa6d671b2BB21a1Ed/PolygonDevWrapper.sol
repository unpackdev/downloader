// SPDX-License-Identifier: MPL-2.0
pragma solidity 0.8.4;

import "./console.sol";
import "./ERC20PresetMinterPauserUpgradeable.sol";
import "./SafeERC20.sol";
import "./OwnableUpgradeable.sol";
import "./IMintRenounceable.sol";
import "./IWrappable.sol";

contract PolygonDevWrapper is
	IWrappable,
	ERC20PresetMinterPauserUpgradeable,
	OwnableUpgradeable
{
	using SafeERC20 for IERC20;

	address public devAddress;

	function __init(address _devAddress) public initializer {
		super.initialize("Polygon Dev Wrapper", "WDEV");
		__Ownable_init();
		devAddress = _devAddress;
	}

	/**
	 * Wrap DEV to create Polygon compatible token
	 */
	function wrap(uint256 _amount) external override returns (bool) {
		IERC20 _token = IERC20(devAddress);
		require(
			_token.balanceOf(address(msg.sender)) >= _amount,
			"Insufficient balance"
		);
		_token.safeTransferFrom(msg.sender, address(this), _amount);
		_mint(msg.sender, _amount);
		return true;
	}

	/**
	 * Burn pegged token and return DEV
	 */
	function unwrap(uint256 _amount) external override returns (bool) {
		require(balanceOf(msg.sender) >= _amount, "Insufficient balance");
		IERC20 _token = IERC20(devAddress);
		uint256 balanceOfThis = _token.balanceOf(address(this));
		uint256 needsMints = balanceOfThis > _amount
			? 0
			: _amount - balanceOfThis;
		if (needsMints > 0) {
			ERC20PresetMinterPauserUpgradeable(devAddress).mint(
				address(this),
				needsMints
			);
		}
		IERC20(devAddress).safeTransfer(msg.sender, _amount);
		_burn(msg.sender, _amount);
		return true;
	}

	/** Safety measure to transfer DEV to owner */
	function transferDev() external onlyOwner returns (bool) {
		IERC20 _token = IERC20(devAddress);
		uint256 balance = _token.balanceOf(address(this));
		return _token.transfer(msg.sender, balance);
	}

	/**
	 * Delete mint role
	 */
	function renounceMinter() external onlyOwner {
		IMintRenounceable(devAddress).renounceMinter();
	}
}
