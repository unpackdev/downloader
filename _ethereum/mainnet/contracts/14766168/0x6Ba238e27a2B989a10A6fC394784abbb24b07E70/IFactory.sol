// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

/**
 * @title Cart factory
 *
 * @notice An abstraction representing a factory, see CartPoolFactory for details
 *
 */
interface IFactory {

    struct PoolData {
        // @dev pool token address (like CART)
        address poolToken;
        // @dev pool address (like deployed core pool instance)
        address poolAddress;
        // @dev pool weight (200 for CART pools, 800 for CART/ETH pools - set during deployment)
        uint256 weight;
        // @dev flash pool flag
        bool isFlashPool;
    }

    function FACTORY_UID() external view returns (uint256);

    function CART() external view returns (address);

    function cartPerBlock() external view returns (uint256);
    
    function totalWeight() external view returns (uint256);

    function endBlock() external view returns (uint256);

    function getPoolData(address _poolToken) external view returns (PoolData memory);

    function getPoolAddress(address poolToken) external view returns (address);

    function isPoolExists(address _pool) external view returns (bool);
    
    function mintYieldTo(address _to, uint256 _amount) external;
}