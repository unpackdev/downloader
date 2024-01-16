// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./VestingEscrowEnumsUpgradeable.sol";
import "./VestingEscrowConstantsUpgradeable.sol";
import "./Initializable.sol";

/**
 * @title VestingEscrowStorageUpgradeable
 * @author NeatFi
 * @notice This contract holds the structs for the Vesting Escrow contract.
 */
contract VestingEscrowStorageUpgradeable is
    Initializable,
    VestingEscrowEnumsUpgradeable,
    VestingEscrowConstantsUpgradeable
{
    /**
     * @dev The Vesting struct.
     */
    struct Vesting {
        // The address of the vestee.
        address vestee;
        // The amount of Neat tokens to be vested.
        uint256 tokenAmount;
        // The amount of initially available tokens. Those are available prior
        uint256 initiallyAvailableTokens;
        // The amount of claimed tokens by the vestee.
        uint256 claimedTokens;
        // The timestamp of vesting start.
        uint256 startingAt;
        // The timestamp of vesting end.
        uint256 endingAt;
        // The period of vesting in months.
        uint256 vestingPeriod;
        // The vesting cliff in days (0 if no cliff).
        uint256 cliffEndsAt;
        // The timestamp of last claimed tokens for vesting.
        uint256 lastClaimAt;
        // The status of vesting.
        VestingStatus vestingStatus;
    }

    /**
     * @dev Maps the address of the vestee to its corresponding Vesting
     *      struct record.
     */
    mapping(address => Vesting) public vestingInfo;

    // The address of the Neat Token contract.
    address public neatToken;

    /** Initializers */

    function __VestingEscrowStorage_init(address _neatToken)
        internal
        initializer
    {
        neatToken = _neatToken;

        __VestingEscrowEnums_init();
        __VestingEscrowConstants_init();
    }
}
