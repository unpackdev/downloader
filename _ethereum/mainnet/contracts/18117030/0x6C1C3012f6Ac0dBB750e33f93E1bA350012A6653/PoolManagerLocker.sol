// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.19;

import "./IDittoPool.sol";
import "./PoolManager.sol";
import "./IPoolManager.sol";

/**
 * @title PoolManagerLocker
 * @notice Contract that manages the update of Ditto pools, according to prespecified constraints
 *   that lock down all admin functions
 */
contract PoolManagerLocker is PoolManager {

    /**
     * @notice Initialize the contract
     */
    function initialize(address dittoPool_, bytes memory initializationData) public {
        if (_initialized) {
            revert PoolManagerInitialized();
        }
        _initialized = true;
        _dittoPool = IDittoPool(dittoPool_);

        address owner;
        (owner) = abi.decode(initializationData, (address));
        _transferOwnership(owner);
    }

    ///@inheritdoc IPoolManager
    function changeAdminFeeRecipient(address newAdminFeeRecipient_) external onlyOwner {
        _dittoPool.changeAdminFeeRecipient(newAdminFeeRecipient_);
    }

    // ============================================================
    // ================ UNSUPPORTED OPERATIONS ====================
    // ============================================================

    /**
     * @notice Ownership transfer is prohibited for this PoolManager contract
     */
    function transferOwnership(address /*newOwner_*/ ) public pure override {
        revert PoolManagerUnsupportedOperation();
    }

    /**
     * @notice Ownership transfer is prohibited for the underlying DittoPool.
     */
    function transferPoolOwnership(address /*newOwner_*/ ) public pure override {
        revert PoolManagerUnsupportedOperation();
    }

    /**
     * @dev Restricted base price update mechanism
     */
    function changeBasePrice(uint128 /*newBasePrice*/ ) public pure override {
        revert PoolManagerUnsupportedOperation();
    }

    /**
     * @dev Restricted delta update mechanism
     */
    function changeDelta(uint128 /*newDelta_*/ ) public pure override {
        revert PoolManagerUnsupportedOperation();
    }

    /**
     * @dev Restricted lp fee update mechanism
     */
    function changeLpFee(uint96 /*newFeeLp_*/ ) public pure override {
        revert PoolManagerUnsupportedOperation();
    }

    /**
     * @dev Restricted admin fee update mechanism
     */
    function changeAdminFee(uint96 /*newFeeAdmin_*/ ) public pure override {
        revert PoolManagerUnsupportedOperation();
    }
}
