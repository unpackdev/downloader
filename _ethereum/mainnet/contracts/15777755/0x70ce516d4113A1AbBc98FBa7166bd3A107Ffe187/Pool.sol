// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "./IERC20Upgradeable.sol";
import "./Initializable.sol";
import "./OwnableUpgradeable.sol";
import "./DataTypes.sol";
import "./DepositLogic.sol";
import "./PoolLogic.sol";
import "./ReserveLogic.sol";
import "./thToken.sol";
import "./IThToken.sol";
import "./IPool.sol";
import "./PoolStorage.sol";

contract Pool is Initializable, OwnableUpgradeable, PoolStorage, IPool {
	using ReserveLogic for DataTypes.Reserve;

	function initialize() external initializer {
		_repayPeriod = 30 days;
		__Ownable_init();
	}

	function initReserve(
		address underlyingAsset,
		address thTokenAddress
	) external onlyOwner returns (bool) {
		bool initialized = PoolLogic.initReserve(_reserves, _reservesList, underlyingAsset, thTokenAddress);
		return initialized;
	}

	function deposit(
		address underlyingAsset,
		uint256 amount
	) public virtual override {
		DepositLogic.deposit(_reserves, underlyingAsset, amount);
	}
	
	function withdraw(
		address underlyingAsset,
		uint256 amount
	) public virtual override {
		DepositLogic.withdraw(_reserves, underlyingAsset, amount);
	}

	function getReserve(address asset) external view returns(DataTypes.Reserve memory) {
		return _reserves[asset];
	}
}