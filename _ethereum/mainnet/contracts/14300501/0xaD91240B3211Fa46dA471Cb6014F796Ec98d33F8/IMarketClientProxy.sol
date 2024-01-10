// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";
import "./IMarketController.sol";

/**
 * @title IMarketClientProxy
 *
 * @notice Allows upgrading the implementation, market controller, and access controller
 * of a MarketClientProxy
 *
 * The ERC-165 identifier for this interface is: 0x9bc69c79
 *
 * @author Cliff Hall <cliff@futurescale.com> (https://twitter.com/seaofarrows)
 */
interface IMarketClientProxy {

    // Events
    event Upgraded(address indexed implementation);
    event MarketControllerAddressChanged(address indexed marketController);
    event AccessControllerAddressChanged(address indexed accessController);

    /**
     * @dev Set the implementation address
     */
    function setImplementation(address _implementation) external;

    /**
     * @dev Get the implementation address
     */
    function getImplementation() external view returns (address);

    /**
     * @notice Set the Seen.Haus AccessController
     *
     * Emits an AccessControllerAddressChanged event.
     *
     * @param _accessController - the Seen.Haus AccessController address
     */
    function setAccessController(address _accessController) external;

    /**
     * @notice Gets the address of the Seen.Haus AccessController contract.
     *
     * @return the address of the AccessController contract
     */
    function getAccessController() external view returns (IAccessControlUpgradeable);

    /**
     * @notice Set the Seen.Haus MarketController
     *
     * Emits an MarketControllerAddressChanged event.
     *
     * @param _marketController - the Seen.Haus MarketController address
     */
    function setMarketController(address _marketController) external;

    /**
     * @notice Gets the address of the Seen.Haus MarketController contract.
     *
     * @return the address of the MarketController contract
     */
    function getMarketController() external view returns(IMarketController);

}