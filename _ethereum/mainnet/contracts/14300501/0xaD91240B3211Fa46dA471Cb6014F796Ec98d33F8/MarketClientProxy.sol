// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";
import "./IMarketClientProxy.sol";
import "./IMarketController.sol";
import "./SeenConstants.sol";
import "./MarketClientLib.sol";
import "./Proxy.sol";

/**
 * @title MarketClientProxy
 *
 * @notice Delegates calls to a market client implementation contract,
 * such that functions on it execute in the context (address, storage)
 * of this proxy, allowing the implementation contract to be upgraded
 * without losing the accumulated state data.
 *
 * Market clients are the contracts in the system that communicate with
 * the MarketController as clients of the MarketDiamond rather than acting
 * as facets of the MarketDiamond. They include SeenHausNFT, ItemsTicketer,
 * and LotsTicketer.
 *
 * Each Market Client contract will be deployed behind its own proxy for
 * future upgradability.
 *
 * @author Cliff Hall <cliff@futurescale.com> (https://twitter.com/seaofarrows)
 */
contract MarketClientProxy is IMarketClientProxy, SeenConstants, Proxy {

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

    constructor(
        address _accessController,
        address _marketController,
        address _impl
    ) {

        // Get the ProxyStorage struct
        MarketClientLib.ProxyStorage storage ps = MarketClientLib.proxyStorage();

        // Store the AccessController address
        ps.accessController = IAccessControlUpgradeable(_accessController);

        // Store the MarketController address
        ps.marketController = IMarketController(_marketController);

        // Store the implementation address
        ps.implementation = _impl;

    }

    /**
     * @dev Returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation()
    internal
    view
    override
    returns (address) {

        // Get the ProxyStorage struct
        MarketClientLib.ProxyStorage storage ps = MarketClientLib.proxyStorage();

        // Return the current implementation address
        return ps.implementation;

    }

    /**
     * @dev Set the implementation address
     */
    function setImplementation(address _impl)
    external
    onlyRole(UPGRADER)
    override
    {
        // Get the ProxyStorage struct
        MarketClientLib.ProxyStorage storage ps = MarketClientLib.proxyStorage();

        // Store the implementation address
        ps.implementation = _impl;

        // Notify listeners about state change
        emit Upgraded(_impl);

    }

    /**
     * @dev Get the implementation address
     */
    function getImplementation()
    external
    view
    override
    returns (address) {
        return _implementation();
    }

    /**
     * @notice Set the Seen.Haus AccessController
     *
     * Emits an AccessControllerAddressChanged event.
     *
     * @param _accessController - the Seen.Haus AccessController address
     */
    function setAccessController(address _accessController)
    external
    onlyRole(UPGRADER)
    override
    {
        // Get the ProxyStorage struct
        MarketClientLib.ProxyStorage storage ps = MarketClientLib.proxyStorage();

        // Store the AccessController address
        ps.accessController = IAccessControlUpgradeable(_accessController);

        // Notify listeners about state change
        emit AccessControllerAddressChanged(_accessController);
    }

    /**
     * @notice Gets the address of the Seen.Haus AccessController contract.
     *
     * @return the address of the AccessController contract
     */
    function getAccessController()
    public
    view
    override
    returns(IAccessControlUpgradeable)
    {
        // Get the ProxyStorage struct
        MarketClientLib.ProxyStorage storage ps = MarketClientLib.proxyStorage();

        // Return the current AccessController address
        return ps.accessController;
    }

    /**
     * @notice Set the Seen.Haus MarketController
     *
     * Emits an MarketControllerAddressChanged event.
     *
     * @param _marketController - the Seen.Haus MarketController address
     */
    function setMarketController(address _marketController)
    external
    onlyRole(UPGRADER)
    override
    {
        // Get the ProxyStorage struct
        MarketClientLib.ProxyStorage storage ps = MarketClientLib.proxyStorage();

        // Store the MarketController address
        ps.marketController = IMarketController(_marketController);

        // Notify listeners about state change
        emit MarketControllerAddressChanged(_marketController);
    }

    /**
     * @notice Gets the address of the Seen.Haus MarketController contract.
     *
     * @return the address of the MarketController contract
     */
    function getMarketController()
    public
    override
    view
    returns(IMarketController)
    {
        // Get the ProxyStorage struct
        MarketClientLib.ProxyStorage storage ps = MarketClientLib.proxyStorage();

        // Return the current MarketController address
        return ps.marketController;
    }

}