// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.19;

// Uncomment this line to use console.log

//import "./console.sol";

import "./IRewardsRedeemer.sol";

import "./Clones.sol";
import "./AccessControl.sol";

/**
 * @title Rewards Redeemer Factory
 * @notice Allows to create new Rewards Redeemer contracts by partners.
 * @dev The message sender has to be whitelisted as a Partner in order to create instance of the RewardsRedeemer contract.
 */
interface IRewardsRedeemerFactory {
    /// EVENTS
    event RewardsRedeemerCreated(IRewardsRedeemer indexed rewardsRedeemer, address indexed partner);

    /// FUNCTIONS

    /**
     * @notice Adds a new partner to the whitelist.
     *
     * @param partner Address of the partner to be added to the whitelist.
     */
    function addPartner(address partner) external;

    /**
     * @notice Removes a partner from the whitelist.
     *
     * @param partner Address of the partner to be removed from the whitelist.
     */
    function removePartner(address partner) external;

    /**
     * @notice Creates a new instance of the RewardsRedeemer contract.
     *
     * @param rewardsToken Address of the rewards token.
     *
     * @return rewardsRedeemer Address of the newly created RewardsRedeemer contract.
     */
    function createRewardsRedeemer(address rewardsToken) external returns (IRewardsRedeemer);
}
