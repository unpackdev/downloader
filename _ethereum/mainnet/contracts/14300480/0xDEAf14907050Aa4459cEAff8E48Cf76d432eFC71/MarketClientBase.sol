// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "./IMarketController.sol";
import "./SeenConstants.sol";
import "./SeenTypes.sol";
import "./MarketClientLib.sol";


/**
 * @title MarketClientBase
 *
 * @notice Extended by Seen.Haus contracts that need to communicate with the
 * MarketController, but are NOT facets of the MarketDiamond.
 *
 * Market client contracts include SeenHausNFT, ItemsTicketer, and LotsTicketer
 *
 * @author Cliff Hall <cliff@futurescale.com> (https://twitter.com/seaofarrows)
 */
abstract contract MarketClientBase is SeenTypes, SeenConstants {

    /**
     * @dev Modifier that checks that the caller has a specific role.
     *
     * Reverts if caller doesn't have role.
     *
     * See: {AccessController.hasRole}
     */
    modifier onlyRole(bytes32 role) {
        require(MarketClientLib.hasRole(role), "Caller doesn't have role");
        _;
    }

    /**
     * @notice Get the MarketController from the MarketClientProxy's storage
     *
     * @return IMarketController address
     */
    function getMarketController()
    internal
    pure
    returns (IMarketController)
    {
        MarketClientLib.ProxyStorage memory ps = MarketClientLib.proxyStorage();
        return ps.marketController;
    }

    /**
     * @notice Get a percentage of a given amount.
     *
     * N.B. Represent ercentage values are stored
     * as unsigned integers, the result of multiplying the given percentage by 100:
     * e.g, 1.75% = 175, 100% = 10000
     *
     * @param _amount - the amount to return a percentage of
     * @param _percentage - the percentage value represented as above
     */
    function getPercentageOf(uint256 _amount, uint16 _percentage)
    internal
    pure
    returns (uint256 share)
    {
        share = _amount * _percentage / 10000;
    }

}