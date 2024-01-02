// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity 0.8.17;

/**
 * @title Capped
 * @notice Mixin contract responsible for managing a cap on a Vault.
 * The cap limits the maximum amount that can be handled by the Vault.
 * @dev This contract provides mechanisms to set, update, and utilize a cap for a Vault.
 * It includes functions for checking available cap space, spending cap, and restoring cap.
 * It is designed to be used as part of a larger system, such as a Vault, which would
 * incorporate these cap functionalities.
 * @author Pods Finance
 */
abstract contract Capped {
    // Maximum cap amount
    uint256 public maxCap;

    // Amount of cap already used
    uint256 private _spentCap;

    // Represents an unlimited cap
    uint256 private constant INFINITE_CAP = type(uint256).max;

    // Event emitted when the cap is updated
    event CapUpdated(uint256 newCap);

    // Error thrown when the amount exceeds the available cap
    error Capped__AmountExceedsCap(uint256 amount, uint256 available);

    /**
     * @dev Constructor for the Capped contract.
     * Initializes the contract by setting the cap to INFINITE_CAP.
     * This effectively means there is no limit (or an infinite cap) on the
     * amount that can be handled by the Vault initially. This can be later
     * changed by calling the setCap function.
     */
    constructor() {
        _setCap(INFINITE_CAP);
    }

    /**
     * @notice Updates the cap for the Vault.
     * @dev Virtual function to set a new cap. Should be implemented in derived contracts.
     * @param newCap The new cap value to be set.
     */
    function setCap(uint256 newCap) external virtual;

    /**
     * @dev Internal function to update the cap.
     * @param newCap The new cap value to be set. This value replaces the existing cap.
     */
    function _setCap(uint256 newCap) internal {
        maxCap = newCap;
        emit CapUpdated(newCap);
    }

    /**
     * @dev Returns the available cap space. If the cap is set to
     * INFINITE_CAP, it returns MAX_UINT.
     * @return The amount of cap that is still available for use.
     */
    function availableCap() public view returns (uint256) {
        if (maxCap == INFINITE_CAP) {
            return INFINITE_CAP;
        }

        return maxCap > _spentCap ? maxCap - _spentCap : 0;
    }

    /**
     * @notice Utilizes a portion of the cap.
     * @dev Increases the amount of cap used. If the amount exceeds the
     * available cap, the transaction is reverted with Capped__AmountExceedsCap error.
     * @param amount The amount to be spent from the cap.
     */
    function _spendCap(uint256 amount) internal {
        uint256 available = availableCap();
        if (amount > available) revert Capped__AmountExceedsCap(amount, available);
        _spentCap += amount;
    }

    /**
     * @notice Decreases the used cap by a specified amount.
     * @dev Restores a portion of the cap.
     * @param amount The amount of cap to be restored. This amount is subtracted from
     * the _spentCap. It's used typically when unwinding or reversing operations that
     * previously used cap space.
     */
    function _restoreCap(uint256 amount) internal {
        if (availableCap() != INFINITE_CAP) {
            _spentCap -= amount;
        }
    }
}
