// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./IRegistry.sol";
import "./IPool.sol";

import "./Error.sol";

import "./EnumerableSet.sol";
import "./Ownable2Step.sol";

contract Registry is Ownable2Step, IRegistry {
    using EnumerableSet for EnumerableSet.AddressSet;

    /// @notice EnumerableSet where all the approved pools are stored
    EnumerableSet.AddressSet private pools;
    /**
     * @notice EnumerableSet where all the pending pools are stored
     * These pools can be either approved or rejected by the owner
     */
    EnumerableSet.AddressSet private pendingPools;

    /// @notice the address of the PoolFactory
    address public factory;

    /*///////////////////////////////////////////////////////////////
                        	CONSTRUCTOR
    ///////////////////////////////////////////////////////////////*/

    constructor(address _owner) Ownable(_owner) { }

    /*///////////////////////////////////////////////////////////////
                        VIEW FUNCTIONS
    ///////////////////////////////////////////////////////////////*/

    /// @inheritdoc IRegistry
    function getPoolAt(uint256 _index, bool isPending) external view returns (address) {
        return isPending ? pendingPools.at(_index) : pools.at(_index);
    }

    /// @inheritdoc IRegistry
    function getPoolCount(bool isPending) external view returns (uint256) {
        return isPending ? pendingPools.length() : pools.length();
    }

    /// @inheritdoc IRegistry
    function hasPool(address _pool, bool isPending) external view returns (bool) {
        return isPending ? pendingPools.contains(_pool) : pools.contains(_pool);
    }

    /*///////////////////////////////////////////////////////////////
                            SETTERS
    ///////////////////////////////////////////////////////////////*/

    /// @inheritdoc IRegistry
    function setFactory(address _newFactory) external onlyOwner {
        _setFactory(_newFactory);
    }

    /*///////////////////////////////////////////////////////////////
                        MUTATIVE FUNCTIONS
    ///////////////////////////////////////////////////////////////*/

    /// @inheritdoc IRegistry
    function registerPool(address _newPool) external onlyFactory {
        if (_newPool == address(0)) revert Error.ZeroAddress();
        if (!pendingPools.add(_newPool)) revert Error.AddFailed();
        emit PoolPending(_newPool);
    }

    /// @inheritdoc IRegistry
    function approvePool(address _pool) external onlyOwner {
        if (!pools.add(_pool)) revert Error.AddFailed();
        if (!pendingPools.remove(_pool)) revert Error.RemoveFailed();
        emit PoolApproved(_pool);
        IPool(_pool).approvePool();
    }

    /// @inheritdoc IRegistry
    function rejectPool(address _pool) external onlyOwner {
        if (!pendingPools.remove(_pool)) revert Error.RemoveFailed();
        emit PoolRejected(_pool);
        IPool(_pool).rejectPool();
    }

    /// @inheritdoc IRegistry
    function removePool(address _pool) external onlyOwner {
        if (!pools.remove(_pool)) revert Error.RemoveFailed();
        emit PoolRemoved(_pool);
    }

    /*///////////////////////////////////////////////////////////////
    								INTERNAL FUNCTIONS
    ///////////////////////////////////////////////////////////////*/

    /**
     * @notice Modifies the factory address
     * @param _newFactory The new factory address
     */
    function _setFactory(address _newFactory) internal {
        if (_newFactory == address(0)) revert Error.ZeroAddress();
        emit FactorySet(factory, _newFactory);
        factory = _newFactory;
    }

    /*///////////////////////////////////////////////////////////////
    									MODIFIERS
    ///////////////////////////////////////////////////////////////*/

    modifier onlyFactory() {
        if (msg.sender != factory) revert Error.Unauthorized();
        _;
    }
}
