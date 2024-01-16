// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./ReentrancyGuardUpgradeable.sol";
import "./UUPSUpgradeable.sol";
import "./VestingEscrowOperationsUpgradeable.sol";

/**
 * @title VestingEscrowV1
 * @author NeatFi
 * @notice This contract is the externally facing current implementation of
 *         Neat token vesting contract. All Neat tokens are vested on this contract
 *         through the Neat Treasurer contract.
 */
contract VestingEscrowV1 is
    VestingEscrowOperationsUpgradeable,
    ReentrancyGuardUpgradeable,
    UUPSUpgradeable
{
    // The name of the contract implementation.
    string private name;

    // The version of the contract implementation.
    string private currentVersion;

    /**
     * @dev Sets the version for the current implementation of this contract.
     */
    function _setVersion(string memory newVersion) internal {
        currentVersion = newVersion;
    }

    /**
     * @notice External function to create the Vesting struct record.
     * @dev Only available to the Neat Treasurer contract.
     * @param vestee - The adress of the vestee.
     * @param tokenAmount - The amount of vested tokens.
     * @param cliffDays - The amount of days if there is a vesting cliff.
     * @param initiallyAvailableTokens - The amount of tokens that are
     *                                   available to be claimed after
     *                                   the creation of vesting.
     * @param periodMonths - The vesting period in months.
     */
    function vest(
        address vestee,
        uint256 tokenAmount,
        uint256 cliffDays,
        uint256 initiallyAvailableTokens,
        uint256 periodMonths
    ) external onlyRole(AUTHORIZED_OPERATOR) {
        _vest(
            vestee,
            tokenAmount,
            cliffDays,
            initiallyAvailableTokens,
            periodMonths
        );
    }

    /**
     * @notice External function to terminate vesting for a vestee.
     * @dev Only available to the current default admin role holder.
     * @param vestee - The adress of the vestee.
     */
    function terminate(address vestee)
        external
        nonReentrant
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _terminate(vestee);
    }

    /**
     * @notice Public function to check if the message sender can claim
     *         vested tokens.
     * @return availableNeatsToClaim - The amount of tokens that the vestee
     *                                 can claim.
     */
    function availableToClaim()
        public
        view
        returns (uint256 availableNeatsToClaim)
    {
        return _availableToClaim(_msgSender());
    }

    /**
     * @notice Public function for the message sender to claim available tokens.
     */
    function claim() public nonReentrant {
        _claim(_msgSender());
    }

    /** Initializers */

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyRole(PROTOCOL_ADMIN)
    {}

    function initialize(address _neatToken) public initializer onlyProxy {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

        __UUPSUpgradeable_init();
        __VestingEscrowOperations_init(_neatToken);

        name = "NeatFi Vesting Escrow";
        _setVersion("1.0.0");
    }
}
