// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "./SeenTypes.sol";

/**
 * @title IMarketController
 *
 * @notice Manages configuration and consignments used by the Seen.Haus contract suite.
 * @dev Contributes its events and functions to the IMarketController interface
 *
 * The ERC-165 identifier for this interface is: 0x57f9f26d
 *
 * @author Cliff Hall <cliff@futurescale.com> (https://twitter.com/seaofarrows)
 */
interface IMarketConfigAdditional {

    /// Events
    event AllowExternalTokensOnSecondaryChanged(bool indexed status);
    event EscrowAgentFeeChanged(address indexed escrowAgent, uint16 fee);
    
    /**
     * @notice Sets whether or not external tokens can be listed on secondary market
     *
     * Emits an AllowExternalTokensOnSecondaryChanged event.
     *
     * @param _status - boolean of whether or not external tokens are allowed
     */
    function setAllowExternalTokensOnSecondary(bool _status) external;

    /**
     * @notice The allowExternalTokensOnSecondary getter
     */
    function getAllowExternalTokensOnSecondary() external view returns (bool status);

        /**
     * @notice The escrow agent fee getter
     */
    function getEscrowAgentFeeBasisPoints(address _escrowAgentAddress) external view returns (uint16);

    /**
     * @notice The escrow agent fee setter
     */
    function setEscrowAgentFeeBasisPoints(address _escrowAgentAddress, uint16 _basisPoints) external;
}