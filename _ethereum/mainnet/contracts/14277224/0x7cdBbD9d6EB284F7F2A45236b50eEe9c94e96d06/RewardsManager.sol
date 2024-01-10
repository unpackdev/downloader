// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
pragma abicoder v2;

import "./IRewardsManager.sol";
import "./Initializable.sol";
import "./OwnableUpgradeable.sol";
import "./EnumerableSetUpgradeable.sol";

contract RewardsManager is IRewardsManager, Initializable, Ownable {
    using EnumerableSet for EnumerableSet.AddressSet;

    EnumerableSet.AddressSet private excludePools;

    function initialize() public initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function registerExcludePools(address[] calldata pools) external override onlyOwner {
        for (uint256 i = 0; i < pools.length; i++) {
            require(pools[i] != address(0), "ZERO_ADDRESS");
            require(excludePools.add(pools[i]), "ADD_FAIL");
        }

        emit ExcludePoolsRegistered(pools);
    }

    function unregisterExcludePools(address[] calldata pools) external override onlyOwner {
        for (uint256 i = 0; i < pools.length; i++) {
            require(excludePools.remove(pools[i]), "REMOVE_FAIL");
        }

        emit ExcludePoolsUnRegistered(pools);
    }

    function getExcludePools() public view override returns (address[] memory pools) {
        uint256 length = excludePools.length();
        pools = new address[](length);

        for (uint256 i = 0; i < length; i++) {
            pools[i] = excludePools.at(i);
        }
    }

}
