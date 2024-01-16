// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./ContextUpgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "./VestingEscrowEventsUpgradeable.sol";
import "./IERC20.sol";

/**
 * @title VestingEscrowEventsUpgradeable
 * @author NeatFi
 * @notice This contract holds the operations for the Vesting Escrow contract.
 */
contract VestingEscrowOperationsUpgradeable is
    ContextUpgradeable,
    AccessControlUpgradeable,
    VestingEscrowEventsUpgradeable
{
    /**
     * @notice Internal function to create the Vesting struct record.
     * @param vestee - The adress of the vestee.
     * @param tokenAmount - The amount of vested tokens.
     * @param cliffDays - The amount of days if there is a vesting cliff.
     * @param initiallyAvailableTokens - The amount of tokens that are
     *                                   available to be claimed after
     *                                   the creation of vesting.
     * @param periodMonths - The vesting period in months.
     */
    function _vest(
        address vestee,
        uint256 tokenAmount,
        uint256 cliffDays,
        uint256 initiallyAvailableTokens,
        uint256 periodMonths
    ) internal {
        require(
            periodMonths > 0 && periodMonths <= 48,
            "VestingEscrowOperationsUpgradeable::_vest: wrong periodMonths."
        );

        require(
            cliffDays >= 0 && cliffDays <= 365,
            "VestingEscrowOperationsUpgradeable::_vest: wrong periodMonths."
        );

        Vesting memory v = Vesting(
            vestee,
            tokenAmount - initiallyAvailableTokens,
            initiallyAvailableTokens,
            0,
            block.timestamp,
            block.timestamp + periodMonths * MONTH,
            periodMonths,
            block.timestamp + cliffDays * DAY,
            0,
            VestingStatus.VESTING
        );

        vestingInfo[vestee] = v;

        emit VestingStarted(v);
    }

    /**
     * @notice Internal function to terminate vesting for a vestee.
     * @param vestee - The adress of the vestee.
     */
    function _terminate(address vestee) internal {
        Vesting storage v = vestingInfo[vestee];

        require(
            block.timestamp <= v.endingAt,
            "VestingEscrowOperationsUpgradeable::_terminate: can't terminate a vesting when it's fully vested."
        );

        v.vestingStatus = VestingStatus.TERMINATED;

        emit Terminated(vestee);

        uint256 neatsToClaim = _availableToClaim(vestee);

        // Transferring any vested tokens to the vestee.
        if (neatsToClaim != 0) {
            IERC20(neatToken).transfer(vestee, neatsToClaim);
            v.claimedTokens += neatsToClaim;
        }
    }

    /**
     * @notice Internal function to check if a given address has vested tokens.
     * @param vestee - The adress of the vestee.
     */
    function _exists(address vestee) internal view returns (bool) {
        Vesting storage v = vestingInfo[vestee];
        if (v.vestee == vestee) {
            return true;
        } else {
            return false;
        }
    }

    /**
     * @notice Internal function to check if a given address can claim
     *         vested tokens.
     * @param vestee - The adress of the vestee.
     * @return availableNeatsToClaim - The amount of tokens that the vestee
     *                                 can claim.
     */
    function _availableToClaim(address vestee)
        internal
        view
        returns (uint256 availableNeatsToClaim)
    {
        require(
            _exists(vestee),
            "VestingEscrowOperationsUpgradeable::_availableToClaim: the address has no vested Neats."
        );

        Vesting storage v = vestingInfo[vestee];

        if (block.timestamp >= v.endingAt) {
            availableNeatsToClaim = v.tokenAmount - v.claimedTokens;
        } else {
            uint256 availableToClaimPerMonth = v.tokenAmount /
                (v.vestingPeriod);
            if (v.lastClaimAt != 0) {
                uint256 monthsSinceLastClaim = (block.timestamp -
                    v.lastClaimAt) / MONTH;
                availableNeatsToClaim =
                    availableToClaimPerMonth *
                    monthsSinceLastClaim;
            } else {
                uint256 monthsSinceVestingstart = (block.timestamp -
                    v.startingAt) / MONTH;

                availableNeatsToClaim =
                    availableToClaimPerMonth *
                    monthsSinceVestingstart;
            }
            if (v.initiallyAvailableTokens != 0) {
                availableNeatsToClaim += v.initiallyAvailableTokens;
            }
        }

        return availableNeatsToClaim;
    }

    /**
     * @notice Internal function to claim available tokens.
     * @dev Transfers tokens from this contract to the address of the vestee.
     * @param vestee - The adress of the vestee.
     */
    function _claim(address vestee) internal {
        Vesting storage v = vestingInfo[vestee];

        require(
            _exists(vestee),
            "VestingEscrowOperationsUpgradeable::_claim: no vested tokens for this address."
        );

        require(
            v.vestingStatus == VestingStatus.VESTING,
            "VestingEscrowOperationsUpgradeable::_claim: invalid vesting status."
        );

        if (v.initiallyAvailableTokens == 0) {
            require(
                block.timestamp >= v.cliffEndsAt,
                "VestingEscrowOperationsUpgradeable::_claim: vesting cliff has not yet reached."
            );
        }

        uint256 availableNeatsToClaim = _availableToClaim(vestee);

        require(
            availableNeatsToClaim > 0,
            "VestingEscrowOperationsUpgradeable::_claim: no amount available to claim."
        );

        v.lastClaimAt = block.timestamp;
        v.claimedTokens += availableNeatsToClaim;

        if (v.initiallyAvailableTokens != 0) {
            v.initiallyAvailableTokens = 0;
        }

        if (v.claimedTokens == v.tokenAmount) {
            v.vestingStatus = VestingStatus.FULLY_VESTED;
            emit FullyVested(v);
        }

        emit VestedTokensClaimed(vestee, availableNeatsToClaim);

        IERC20(neatToken).transfer(vestee, availableNeatsToClaim);
    }

    /** Initializers */

    function __VestingEscrowOperations_init(address _neatToken)
        internal
        initializer
    {
        __Context_init();
        __VestingEscrowEvents_init(_neatToken);
        __AccessControl_init();
    }
}
