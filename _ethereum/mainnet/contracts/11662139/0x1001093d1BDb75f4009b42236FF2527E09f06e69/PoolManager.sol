// SPDX-License-Identifier: MIT
pragma solidity >=0.4.21 <0.7.0;

import "./EnumerableSet.sol";

import "./XMust.sol";
import "./Rewarder.sol";

/**
 * @dev PoolManager handle different pool and expose `burnRewards` method to
 * managed pool.
 */
abstract contract PoolManager is Rewarder {
    using EnumerableSet for EnumerableSet.AddressSet;

    EnumerableSet.AddressSet private _pools;

    constructor() public { }

    modifier isManagedPool() {
        require(_pools.contains(msg.sender), "PoolManager: caller is not a managed pool");
        _;
    }

    function _addPool(address pool) internal {
        require(!_pools.contains(pool), "PoolManager: already existing pool");
        _pools.add(pool);
    }

    function _removePool(address pool) internal {
        require(_pools.contains(pool), "PoolManager: unknow pool");
        _pools.remove(pool);
    }

    function burnRewards(address holder, uint256 value) external isManagedPool {
        _beforeAction();
        _burnRewards(holder, value);
    }

    function pools() external view returns(address[] memory) {
        address[] memory result = new address[](_pools.length());
        for (uint i = 0; i <  _pools.length(); i++) {
            result[i] = _pools.at(i) ;
        }
        return result;
    }

    function _beforeAction() internal virtual { }
}
