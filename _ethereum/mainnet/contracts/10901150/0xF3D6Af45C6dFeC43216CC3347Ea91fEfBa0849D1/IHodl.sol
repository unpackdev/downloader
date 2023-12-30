// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface IHodl {
    /**
     * @dev Lock the given amount of PRPS for the specified period (or infinitely)
     * for DUBI.
     */
    function hodl(
        uint24 id,
        uint96 amountPrps,
        uint16 duration,
        address dubiBeneficiary,
        address prpsBeneficiary
    ) external;

    /**
     * @dev Release a hodl of `prpsBeneficiary` with the given `creator` and `id`.
     */
    function release(
        uint24 id,
        address prpsBeneficiary,
        address creator
    ) external;

    /**
     * @dev Withdraw can be used to withdraw DUBI from infinitely locked PRPS.
     * The amount of DUBI withdrawn depends on the time passed since the last withdrawal.
     */
    function withdraw(
        uint24 id,
        address prpsBeneficiary,
        address creator
    ) external;

    /**
     * @dev Burn `amount` of `from`'s locked and/or pending PRPS.
     *
     * This function is supposed to be only called by the PRPS contract.
     *
     * Returns the amount of DUBI that needs to be minted.
     */
    function burnLockedPrps(
        address from,
        uint96 amount,
        uint32 dubiMintTimestamp,
        bool burnPendingLockedPrps
    ) external returns (uint96);

    /**
     * @dev Set `amount` of `from`'s locked PRPS to pending.
     *
     * This function is supposed to be only called by the PRPS contract.
     *
     * Returns the amount of locked PRPS that could be set to pending.
     */
    function setLockedPrpsToPending(address from, uint96 amount) external;

    /**
     * @dev Revert `amount` of `from`'s pending locked PRPS to not pending.
     *
     * This function is supposed to be only called by the PRPS contract and returns
     */
    function revertLockedPrpsSetToPending(address account, uint96 amount)
        external;
}
