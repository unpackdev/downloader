// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./Initializable.sol";

/**
 * @title VestingEscrowEnumsUpgradeable
 * @author NeatFi
 * @notice This contract holds the enums for vesting status.
 */
contract VestingEscrowEnumsUpgradeable is Initializable {
    enum VestingStatus {
        // 0: Vesting is created and is in process.
        VESTING,
        // 1: Tokens are fully vested.
        FULLY_VESTED,
        // 2: Vesting is terminated.
        TERMINATED
    }

    /** Initializers */

    function __VestingEscrowEnums_init() internal initializer {
        __VestingEscrowEnums_init_unchained();
    }

    function __VestingEscrowEnums_init_unchained() internal initializer {}
}
