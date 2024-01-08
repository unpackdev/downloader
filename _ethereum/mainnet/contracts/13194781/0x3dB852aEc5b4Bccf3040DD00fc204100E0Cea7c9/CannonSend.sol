// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./CannonActivity.sol";

/**
 * @title Nifty Cannon Send functions
 *
 * @notice Allows direct or deferred transfer of NFTs from one
 * sender to one or more recipients.
 *
 * @author Cliff Hall <cliff@futurescale.com> (https://twitter.com/seaofarrows)
 */
contract CannonSend is CannonActivity {

    // TODO: Disallow volleys that target addresses behind Rampart

    /**
     * @notice Fire a single Volley
     * This contract must already be approved as an operator for the NFTs specified in the Volley.
     * @param _volley a valid Volley struct
     */
    function fireVolley(Volley memory _volley) external {
        processVolley(_volley);
    }

    /**
     * @notice Fire multiple Volleys
     * This contract must already be approved as an operator for the NFTs specified in the Volleys.
     * @param _volleys an array of valid Volley structs
     */
    function fireVolleys(Volley[] memory _volleys) external {
        for (uint256 index = 0; index < _volleys.length; index++) {
            Volley memory volley = _volleys[index];
            processVolley(volley);
        }
    }
}