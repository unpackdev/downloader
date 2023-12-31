// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.0;

import "./IOwnerTwoStep.sol";

abstract contract OwnerTwoStep is IOwnerTwoStep {

    /// @dev The owner of the contract
    address private _owner;

    /// @dev The pending owner of the contract
    address private _pendingOwner;

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(msg.sender);
    }

    // ***************************************************************
    // * ========================= EVENTS ========================== *
    // ***************************************************************

    event OwnerTwoStepOwnerStartedTransfer(address currentOwner, address newPendingOwner);
    event OwnerTwoStepPendingOwnerAcceptedTransfer(address newOwner);
    event OwnerTwoStepOwnershipTransferred(address previousOwner, address newOwner);
    event OwnerTwoStepOwnerRenouncedOwnership(address previousOwner);

    // ***************************************************************
    // * ========================= ERRORS ========================== *
    // ***************************************************************

    error OwnerTwoStepNotOwner();
    error OwnerTwoStepNotPendingOwner();

    // ***************************************************************
    // * =================== USER INTERFACE ======================== *
    // ***************************************************************

    ///@inheritdoc IOwnerTwoStep
    function transferOwnership(address newPendingOwner_) public virtual override onlyOwner {
        _pendingOwner = newPendingOwner_;

        emit OwnerTwoStepOwnerStartedTransfer(_owner, newPendingOwner_);
    }

    ///@inheritdoc IOwnerTwoStep
    function acceptOwnership() public virtual override onlyPendingOwner {
        emit OwnerTwoStepPendingOwnerAcceptedTransfer(msg.sender);

        _transferOwnership(msg.sender);
    }

    ///@inheritdoc IOwnerTwoStep
    function renounceOwnership() public virtual onlyOwner {

        emit OwnerTwoStepOwnerRenouncedOwnership(msg.sender);

        _transferOwnership(address(0));
    }

    // ***************************************************************
    // * =================== VIEW FUNCTIONS ======================== *
    // ***************************************************************

    ///@inheritdoc IOwnerTwoStep
    function owner() public view virtual override returns (address) {
        return _owner;
    }

    ///@inheritdoc IOwnerTwoStep
    function pendingOwner() external view override returns (address) {
        return _pendingOwner;
    }

    // ***************************************************************
    // * ===================== MODIFIERS =========================== *
    // ***************************************************************

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _onlyOwner();
        _;
    }

    /**
     * @dev Throws if called by any account other than the pending owner.
     */
    modifier onlyPendingOwner {
        if (msg.sender != _pendingOwner) {
            revert OwnerTwoStepNotPendingOwner();
        }
        _;
    }

    // ***************************************************************
    // * ================== INTERNAL HELPERS ======================= *
    // ***************************************************************

    /**
     * @dev Throws if called by any account other than the owner. Saves contract size over copying 
     *   implementation into every function that uses the modifier.
     */
    function _onlyOwner() internal view virtual {
        if (msg.sender != _owner) {
            revert OwnerTwoStepNotOwner();
        }
    }


    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * @param newOwner_ New owner to transfer to
     */
    function _transferOwnership(address newOwner_) internal {
        delete _pendingOwner;

        emit OwnerTwoStepOwnershipTransferred(_owner, newOwner_);

        _owner = newOwner_;
    }
}
