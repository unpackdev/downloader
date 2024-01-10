// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "./IMarketController.sol";
import "./IMarketConfigAdditional.sol";
import "./IMarketClerk.sol";
import "./DiamondLib.sol";
import "./MarketControllerBase.sol";
import "./MarketControllerLib.sol";

/**
 * @title MarketConfigFacet
 *
 * @notice Provides centralized management of various market-related settings.
 *
 * @author Cliff Hall <cliff@futurescale.com> (https://twitter.com/seaofarrows)
 */
contract MarketConfigAdditionalFacet is IMarketConfigAdditional, MarketControllerBase {

    /**
     * @dev Modifier to protect initializer function from being invoked twice.
     */
    modifier onlyUnInitialized()
    {
        MarketControllerLib.MarketControllerInitializers storage mci = MarketControllerLib.marketControllerInitializers();
        require(!mci.configAdditionalFacet, "Initializer: contract is already initialized");
        mci.configAdditionalFacet = true;
        _;
    }

    /**
     * @notice Facet Initializer
     *
     * @param _allowExternalTokensOnSecondary - whether or not external tokens are allowed to be sold via secondary market
     */
    function initialize(
      bool _allowExternalTokensOnSecondary
    )
    public
    onlyUnInitialized
    {
        // Register supported interfaces
        DiamondLib.addSupportedInterface(type(IMarketConfigAdditional).interfaceId);  // when combined with IMarketClerk ...
        DiamondLib.addSupportedInterface(type(IMarketConfigAdditional).interfaceId ^ type(IMarketClerk).interfaceId); // ... supports IMarketController

        // Initialize market config params
        MarketControllerLib.MarketControllerStorage storage mcs = MarketControllerLib.marketControllerStorage();
        mcs.allowExternalTokensOnSecondary = _allowExternalTokensOnSecondary;
    }

    /**
     * @notice Sets whether or not external tokens can be listed on secondary market
     *
     * Emits an AllowExternalTokensOnSecondaryChanged event.
     *
     * @param _status - boolean of whether or not external tokens are allowed
     */
    function setAllowExternalTokensOnSecondary(bool _status)
    external
    override
    onlyRole(MULTISIG)
    {
        MarketControllerLib.MarketControllerStorage storage mcs = MarketControllerLib.marketControllerStorage();
        require(_status != mcs.allowExternalTokensOnSecondary, "Already set to requested status.");
        mcs.allowExternalTokensOnSecondary = _status;
        emit AllowExternalTokensOnSecondaryChanged(mcs.allowExternalTokensOnSecondary);
    }

    /**
     * @notice The allowExternalTokensOnSecondary getter
     */
    function getAllowExternalTokensOnSecondary()
    external
    override
    view
    returns (bool)
    {
        MarketControllerLib.MarketControllerStorage storage mcs = MarketControllerLib.marketControllerStorage();
        return mcs.allowExternalTokensOnSecondary;
    }

    /**
     * @notice The escrow agent fee getter
     *
     * Returns zero if no escrow agent fee is set
     *
     * @param _escrowAgentAddress - the address of the escrow agent
     * @return uint256 - escrow agent fee in basis points
     */
    function getEscrowAgentFeeBasisPoints(address _escrowAgentAddress)
    public
    override
    view
    returns (uint16)
    {
        MarketControllerLib.MarketControllerStorage storage mcs = MarketControllerLib.marketControllerStorage();
        return mcs.escrowAgentToFeeBasisPoints[_escrowAgentAddress];
    }

    /**
     * @notice The escrow agent fee setter
     *
     * Reverts if:
     * - _basisPoints are more than 5000 (50%)
     *
     * @param _escrowAgentAddress - the address of the escrow agent
     * @param _basisPoints - the escrow agent's fee in basis points
     */
    function setEscrowAgentFeeBasisPoints(address _escrowAgentAddress, uint16 _basisPoints)
    external
    override
    onlyRole(MULTISIG)
    {
        // Ensure the consignment exists, has not been released and that basis points don't exceed 5000 (50%)
        require(_basisPoints <= 5000, "_basisPoints over 5000");
        MarketControllerLib.MarketControllerStorage storage mcs = MarketControllerLib.marketControllerStorage();
        mcs.escrowAgentToFeeBasisPoints[_escrowAgentAddress] = _basisPoints;
        emit EscrowAgentFeeChanged(_escrowAgentAddress, _basisPoints);
    }
}