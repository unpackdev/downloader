// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.14;

import "./SelfAuthorized.sol";
import "./IStakeManager.sol";
import "./IAccountAbstraction.sol";

/**
 * @title AccountAbstraction - Handles the entry point address. Can only be changed through a safe transaction.
 */
contract AccountAbstraction is IAccountAbstraction, SelfAuthorized {
    // Entrypoint address should always be located at storage slot 1.
    address public entryPoint;

    /**
     * @dev Inits the entry point address.
     * @param _entryPoint the entry point address.
     */
    function initEntryPoint(address _entryPoint) internal {
        if (_entryPoint.code.length == 0 || _entryPoint == address(this))
            revert AA__initEntryPoint__invalidEntryPoint();

        entryPoint = _entryPoint;
    }

    /**
     * @dev Withdraws deposits from the Entry Point.
     * @param amount The amount to withdraw.
     */
    function withdrawDeposit(uint256 amount) external authorized {
        if (IStakeManager(entryPoint).balanceOf(address(this)) < amount)
            revert AA__withdrawDeposit__insufficientBalance();

        // The stake manager will check for success.
        IStakeManager(entryPoint).withdrawTo(address(this), amount);
    }

    /**
     * @dev Changes the entry point address.
     * @param newEntryPoint  new entry point address.
     */
    function changeEntryPoint(address newEntryPoint) external authorized {
        if (
            newEntryPoint.code.length == 0 ||
            newEntryPoint == address(this) ||
            entryPoint == newEntryPoint
        ) revert AA__changeEntryPoint__invalidEntryPoint();

        entryPoint = newEntryPoint;
        emit EntryPointChanged(entryPoint);
    }
}
