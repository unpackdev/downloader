// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "./MarketControllerLib.sol";
import "./DiamondLib.sol";
import "./SeenTypes.sol";
import "./SeenConstants.sol";

/**
 * @title MarketControllerBase
 *
 * @notice Provides domain and common modifiers to MarketController facets
 *
 * @author Cliff Hall <cliff@futurescale.com> (https://twitter.com/seaofarrows)
 */
abstract contract MarketControllerBase is SeenTypes, SeenConstants {

    /**
     * @dev Modifier that checks that the consignment exists
     *
     * Reverts if the consignment does not exist
     */
    modifier consignmentExists(uint256 _consignmentId) {

        MarketControllerLib.MarketControllerStorage storage mcs = MarketControllerLib.marketControllerStorage();

        // Make sure the consignment exists
        require(_consignmentId < mcs.nextConsignment, "Consignment does not exist");
        _;
    }

    /**
     * @dev Modifier that checks that the caller has a specific role.
     *
     * Reverts if caller doesn't have role.
     *
     * See: {AccessController.hasRole}
     */
    modifier onlyRole(bytes32 _role) {
        DiamondLib.DiamondStorage storage ds = DiamondLib.diamondStorage();
        require(ds.accessController.hasRole(_role, msg.sender), "Caller doesn't have role");
        _;
    }

}