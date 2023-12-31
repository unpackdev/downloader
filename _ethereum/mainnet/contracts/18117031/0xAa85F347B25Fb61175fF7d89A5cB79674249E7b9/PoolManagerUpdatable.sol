// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.19;

import "./IDittoPool.sol";
import "./PoolManager.sol";
import "./IPoolManager.sol";

/**
 * @title PoolManagerUpdatable
 * @notice Restricts the changeBasePrice function to a seperate updater key, prohibits adjustment of delta value on pool.
 */
contract PoolManagerUpdatable is PoolManager {
    
    /// @dev The updater of the contract, used to set values that are often changing.
    address private _updater;

    // ***************************************************************
    // * ========================= EVENTS ========================== *
    // ***************************************************************

    event PoolManagerUpdatableNewUpdater(address updater);

    // ***************************************************************
    // * ========================= ERRORS ========================== *
    // ***************************************************************

    error PoolManagerUpdatableInvalidMsgSender();

    /**
     * @notice Initialize the contract
     */
    function initialize(address dittoPool_, bytes memory initializationData) public {
        if (_initialized) {
            revert PoolManagerInitialized();
        }
        _initialized = true;
        _dittoPool = IDittoPool(dittoPool_);
        (address owner, address initialUpdater) = abi.decode(initializationData, (address, address));
        _transferOwnership(owner);
        _setUpdater(initialUpdater);
    }

    // =================================================================
    // ====================== VIEW FUNCTIONS ===========================
    // =================================================================
    /**
     * @notice Returns the updater of the contract
     */
    function updater() external view returns (address) {
        return _updater;
    }

    // =================================================================
    // ================ UPDATABLE MANAGER OPERATIONS ===================
    // =================================================================

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyUpdater() {
        if (msg.sender != _updater) {
            revert PoolManagerUpdatableInvalidMsgSender();
        }
        _;
    }

    /**
     * @dev Sets the updater of the contract, used to set values that are often changing.
     * @param updater_ The new updater
     */
    function setUpdater(address updater_) external onlyOwner {
        _setUpdater(updater_);
    }

    /**
     * @dev Base price update mechanism, restricted to the updater key
     */
    function changeBasePrice(uint128 newBasePrice) external override onlyUpdater {
        _dittoPool.changeBasePrice(newBasePrice);
    }

    // ==========================================================
    // ================ DITTO POOL OPERATIONS ===================
    // ==========================================================

    ///@inheritdoc IPoolManager
    function changeAdminFeeRecipient(address newAdminFeeRecipient_) external override onlyOwner {
        _dittoPool.changeAdminFeeRecipient(newAdminFeeRecipient_);
    }

    ///@inheritdoc IPoolManager
    function changeLpFee(uint96 newFeeLp_) external override onlyOwner {
        _dittoPool.changeLpFee(newFeeLp_);
    }

    /**
     * @dev Restricted admin fee update mechanism
     */
    function changeAdminFee(uint96 newFeeAdmin_) external override onlyOwner {
        _dittoPool.changeAdminFee(newFeeAdmin_);
    }

    // ============================================================
    // ================ UNSUPPORTED OPERATIONS ====================
    // ============================================================

    /**
     * @dev Restricted delta update mechanism
     */
    function changeDelta(uint128 /*newDelta_*/ ) external pure override {
        revert PoolManagerUnsupportedOperation();
    }

    /**
     * @notice Ownership transfer is prohibited for this PoolManager contract
     */
    function transferOwnership(address /*newOwner_*/ ) public pure override {
        revert PoolManagerUnsupportedOperation();
    }

    /**
     * @notice Ownership transfer is prohibited for the underlying DittoPool.
     */
    function transferPoolOwnership(address /*newOwner_*/ ) external pure override {
        revert PoolManagerUnsupportedOperation();
    }

    // ***************************************************************
    // * ============= INTERNAL HELPER FUNCTIONS =================== *
    // ***************************************************************

    /**
     * @dev Sets the updater of the contract, used to set values that are often changing.
     */
    function _setUpdater(address updater_) private {
        _updater = updater_;
        emit PoolManagerUpdatableNewUpdater(_updater);
    }
}
