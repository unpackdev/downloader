// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IRegistry {
    /*///////////////////////////////////////////////////////////////
                                EVENTS
    ///////////////////////////////////////////////////////////////*/

    event FactorySet(address indexed oldFactory, address indexed newFactory);

    event PoolApproved(address indexed pool);

    event PoolPending(address indexed pool);

    event PoolRejected(address indexed pool);

    event PoolRemoved(address indexed pool);

    /*///////////////////////////////////////////////////////////////
                            VIEW FUNCTIONS
    ///////////////////////////////////////////////////////////////*/

    /**
     * @notice Returns the address of a pool located at _index
     *  @param _index The index of a pool stored in the EnumerableSet
     *  @param _isPending True if looking into the pending pools, false for the approved ones
     * @return The address of a pool
     */
    function getPoolAt(uint256 _index, bool _isPending) external view returns (address);

    /**
     * @notice Returns the total number of pools
     * @param _isPending True if looking into the pending pools, false for the approved ones
     * @return The total number of pools
     */
    function getPoolCount(bool _isPending) external view returns (uint256);

    /**
     * @notice Checks if an address is stored in the pools set
     * @param _pool The address of a pool
     * @param _isPending True if looking into the pending pools, false for the approved ones
     * @return True if the pool has been found, false otherwise
     */
    function hasPool(address _pool, bool _isPending) external view returns (bool);

    /*///////////////////////////////////////////////////////////////
                                SETTERS
    ///////////////////////////////////////////////////////////////*/

    /**
     * @notice Modifies the factory address
     * @param _newFactory The new factory address
     */
    function setFactory(address _newFactory) external;

    /*///////////////////////////////////////////////////////////////
                            MUTATIVE FUNCTIONS
    ///////////////////////////////////////////////////////////////*/

    /**
     * @notice Registers a new pool in the pending queue
     * @param _newPool The address of a pool
     */
    function registerPool(address _newPool) external;

    /**
     * @notice Approves a pool from the pending queue
     * @param _pool The address of a pool
     */
    function approvePool(address _pool) external;

    /**
     * @notice Rejects a pool from the pending queue
     * @param _pool The address of a pool
     */
    function rejectPool(address _pool) external;

    /**
     * @notice Removes a pool from the approved pool Set
     * @param _pool The address of a pool
     */
    function removePool(address _pool) external;
}
