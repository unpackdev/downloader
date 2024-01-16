// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./VestingEscrowStorageUpgradeable.sol";
import "./Initializable.sol";

/**
 * @title VestingEscrowEventsUpgradeable
 * @author NeatFi
 * @notice This contract holds the events for vesting status.
 */
contract VestingEscrowEventsUpgradeable is
    Initializable,
    VestingEscrowStorageUpgradeable
{
    /**
     * @dev Fired when tokens are vested and a Vesting struct record is created.
     * @param vesting - The Vesting struct record.
     */
    event VestingStarted(Vesting vesting);

    /**
     * @dev Fired when vested tokens are claimed by the vestee.
     * @param vestee - The adress of the vestee.
     * @param amount - The amount of claimed tokens.
     */
    event VestedTokensClaimed(address indexed vestee, uint256 amount);

    /**
     * @dev Fired when vesting is terminated.
     * @param vestee - The adress of the vestee.
     */
    event Terminated(address indexed vestee);

    /**
     * @dev Fired when tokens are fully vested.
     * @param vesting - The Vesting struct record.
     */
    event FullyVested(Vesting vesting);

    /** Initializers */

    function __VestingEscrowEvents_init(address _neatToken)
        internal
        initializer
    {
        __VestingEscrowStorage_init(_neatToken);
    }
}
