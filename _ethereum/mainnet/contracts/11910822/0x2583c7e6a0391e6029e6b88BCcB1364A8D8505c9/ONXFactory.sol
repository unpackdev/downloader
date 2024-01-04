// SPDX-License-Identifier: MIT
pragma solidity >=0.5.16;
import "./Configable.sol";

interface IONXPool {
	function init(address supplyToken, address collateralToken) external;

	function setupConfig(address config) external;
}

contract ONXFactory is Configable {
	event PoolCreated(address indexed lendToken, address indexed collateralToken, address indexed pool);
	address[] public allPools;
	mapping(address => bool) public isPool;
	mapping(address => mapping(address => address)) public getPool;

	function initialize() public initializer {
		Configable.__config_initialize();
	}

	function createPool(address pool, address _lendToken, address _collateralToken) external onlyOwner {
		require(getPool[_lendToken][_collateralToken] == address(0), "ALREADY CREATED");
		getPool[_lendToken][_collateralToken] = pool;
		allPools.push(pool);
		isPool[pool] = true;
		IConfig(config).initPoolParams(pool);
		IONXPool(pool).setupConfig(config);
		IONXPool(pool).init(_lendToken, _collateralToken);
		emit PoolCreated(_lendToken, _collateralToken, pool);
	}

	function countPools() external view returns (uint256) {
		return allPools.length;
	}
}
