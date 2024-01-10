// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "./ERC1155HolderUpgradeable.sol";
import "./ERC721HolderUpgradeable.sol";
import "./IERC1155Upgradeable.sol";
import "./IERC721Upgradeable.sol";
import "./IMarketClerk.sol";
import "./DiamondLib.sol";
import "./MarketControllerBase.sol";
import "./MarketControllerLib.sol";

/**
 * @title MarketClerkFacet
 *
 * @notice Manages consignments for the Seen.Haus contract suite.
 *
 * @author Cliff Hall <cliff@futurescale.com> (https://twitter.com/seaofarrows)
 */
contract MarketClerkFacet is IMarketClerk, MarketControllerBase, ERC1155HolderUpgradeable, ERC721HolderUpgradeable {

    /**
     * @dev Modifier to protect initializer function from being invoked twice.
     */
    modifier onlyUnInitialized() {
        MarketControllerLib.MarketControllerInitializers storage mci = MarketControllerLib.marketControllerInitializers();
        require(!mci.clerkFacet, "Initializer: contract is already initialized");
        mci.clerkFacet = true;
        _;
    }

    /**
     * @notice Facet Initializer
     *
     * Register IMarketClerk,
     */
    function initialize()
    public
    onlyUnInitialized
    {
        DiamondLib.addSupportedInterface(type(IMarketClerk).interfaceId);
        DiamondLib.addSupportedInterface(type(IERC1155ReceiverUpgradeable).interfaceId);
        DiamondLib.addSupportedInterface(type(IERC721ReceiverUpgradeable).interfaceId);
    }

    /**
     * @notice The nextConsignment getter
     * @dev does not increment counter
     */
    function getNextConsignment()
    external
    override
    view
    returns (uint256)
    {
        MarketControllerLib.MarketControllerStorage storage mcs = MarketControllerLib.marketControllerStorage();
        return mcs.nextConsignment;
    }

    /**
     * @notice The consignment getter
     *
     * Reverts if consignment doesn't exist
     *
     * @param _consignmentId - the id of the consignment
     * @return consignment - the consignment struct
     */
    function getConsignment(uint256 _consignmentId)
    public
    override
    view
    consignmentExists(_consignmentId)
    returns (Consignment memory consignment)
    {
        MarketControllerLib.MarketControllerStorage storage mcs = MarketControllerLib.marketControllerStorage();
        consignment = mcs.consignments[_consignmentId];
    }

    /**
     * @notice Get the remaining supply of the given consignment.
     *
     * Reverts if consignment doesn't exist
     *
     * @param _consignmentId - the id of the consignment
     * @return  uint256 - the remaining supply held by the MarketController
     */
    function getUnreleasedSupply(uint256 _consignmentId)
    public
    override
    view
    consignmentExists(_consignmentId)
    returns(uint256)
    {
        MarketControllerLib.MarketControllerStorage storage mcs = MarketControllerLib.marketControllerStorage();
        Consignment storage consignment = mcs.consignments[_consignmentId];
        return consignment.supply - consignment.releasedSupply;
    }

    /**
     * @notice Get the consignor of the given consignment
     *
     * Reverts if consignment doesn't exist
     *
     * @param _consignmentId - the id of the consignment
     * @return  address - the consignor's address
     */
    function getConsignor(uint256 _consignmentId)
    public
    override
    view
    consignmentExists(_consignmentId)
    returns(address)
    {
        MarketControllerLib.MarketControllerStorage storage mcs = MarketControllerLib.marketControllerStorage();
        return mcs.consignors[_consignmentId];
    }

    /**
     * @notice Registers a new consignment for sale or auction.
     *
     * Emits a ConsignmentRegistered event.
     *
     * Reverts if:
     *  - Token is multi-token and supply hasn't been transferred to this contract
     *  - Token is not multi-token and contract doesn't implement ERC-721
     *  - Token is not multi-token and this contract is not owner of tokenId
     *  - Token is not multi-token and the supply is not 1
     *
     * @param _market - the market for the consignment. See {SeenTypes.Market}
     * @param _consignor - the address executing the consignment transaction
     * @param _seller - the seller of the consignment
     * @param _tokenAddress - the contract address issuing the NFT behind the consignment
     * @param _tokenId - the id of the token being consigned
     * @param _supply - the amount of the token being consigned
     *
     * @return consignment - the registered consignment
     */
    function registerConsignment(
        Market _market,
        address _consignor,
        address payable _seller,
        address _tokenAddress,
        uint256 _tokenId,
        uint256 _supply
    )
    external
    override
    onlyRole(MARKET_HANDLER)
    returns (Consignment memory consignment)
    {
        MarketControllerLib.MarketControllerStorage storage mcs = MarketControllerLib.marketControllerStorage();

        // Check whether this is a multi token NFT
        bool multiToken = IERC165Upgradeable(_tokenAddress).supportsInterface(type(IERC1155Upgradeable).interfaceId);

        // Ensure consigned asset has been transferred to this this contract
        if (multiToken)  {

            // Ensure this contract has a balance of this token which is at least the value of the supply of the consignment
            // WARNING: In the case of a multiToken, do not rely on this as being a guarantee that the creator of this consignment has transferred a _supply of this token to this contract
            // This is not guaranteed, as in the context of a secondary market, somebody else might have transferred a value equal or greater than _supply to this contract
            // THEREFORE: ALWAYS MAKE SURE THAT THE SUPPLY OF CONSIGNMENT REGISTRATION IS TRANSFERRED TO THIS CONTRACT BEFORE CALLING registerConsignment
            require( IERC1155Upgradeable(_tokenAddress).balanceOf(address(this), _tokenId) >= _supply, "MarketController must own token" );

        } else {

            // Token must be a single token NFT
            require(IERC165Upgradeable(_tokenAddress).supportsInterface(type(IERC721Upgradeable).interfaceId), "Invalid token type");

            // Ensure the consigned token has been transferred to this contract & that supply = 1
            // Rolled into a single require due to contract size
            require((IERC721Upgradeable(_tokenAddress).ownerOf(_tokenId) == (address(this))) && (_supply == 1), "MarketController must own token & supply must be 1");

        }

        // Get the id for the new consignment and increment counter
        uint256 id = mcs.nextConsignment++;

        // Create and store the consignment
        consignment = Consignment(
            _market,
            MarketHandler.Unhandled,
            _seller,
            _tokenAddress,
            _tokenId,
            _supply,
            id,
            multiToken,
            false,
            0,
            0,
            0
        );
        mcs.consignments[id] = consignment;

        // Associate the consignor
        mcs.consignors[id] = _consignor;

        // Notify listeners of state change
        emit ConsignmentRegistered(_consignor, _seller, consignment);
    }

    /**
     * @notice Update consignment to indicate it has been marketed
     *
     * Emits a ConsignmentMarketed event.
     *
     * Reverts if:
     *  - _marketHandler of value Unhandled is passed into this function. See {SeenTypes.MarketHandler}.
     *  - consignment has already been marketed (has a marketHandler other than Unhandled). See {SeenTypes.MarketHandler}.
     *
     * @param _consignmentId - the id of the consignment
     */
    function marketConsignment(uint256 _consignmentId, MarketHandler _marketHandler)
    external
    override
    onlyRole(MARKET_HANDLER)
    consignmentExists(_consignmentId)
    {
        require(_marketHandler != MarketHandler.Unhandled, "requires valid handler");

        MarketControllerLib.MarketControllerStorage storage mcs = MarketControllerLib.marketControllerStorage();

        // Get the consignment into memory
        Consignment storage consignment = mcs.consignments[_consignmentId];

        // A consignment can only be marketed once, should currently be Unhandled
        require(consignment.marketHandler == MarketHandler.Unhandled, "Consignment already marketed");

        // Update the consignment
        consignment.marketHandler = _marketHandler;

        // Consignor address
        address consignor = mcs.consignors[_consignmentId];

        // Notify listeners of state change
        emit ConsignmentMarketed(consignor, consignment.seller, consignment.id);
    }

    /**
     * @notice Release an amount of the consigned token balance to a given address
     *
     * Emits a ConsignmentReleased event.
     *
     * Reverts if:
     *  - caller is does not have MARKET_HANDLER role.
     *  - consignment doesn't exist
     *  - consignment has already been released
     *  - consignment is multi-token and supply is not adequate
     *
     * @param _consignmentId - the id of the consignment
     * @param _amount - the amount of the consigned supply (must be 1 for ERC721 tokens)
     * @param _releaseTo - the address to transfer the consigned token balance to
     */
    function releaseConsignment(uint256 _consignmentId, uint256 _amount, address _releaseTo)
    external
    override
    onlyRole(MARKET_HANDLER)
    consignmentExists(_consignmentId)
    {
        MarketControllerLib.MarketControllerStorage storage mcs = MarketControllerLib.marketControllerStorage();

        // Get the consignment into memory
        Consignment storage consignment = mcs.consignments[_consignmentId];

        // Ensure the consignment has not been released
        require(!consignment.released, "Consigned token already released");

        // Handle transfer, marking of consignment
        if (consignment.multiToken) {

            // Get the current remaining consignment supply
            uint256 remainingSupply = consignment.supply - consignment.releasedSupply;

            // Safety check
            require(_amount <= remainingSupply, "Attempting to release more than is available to consignment");

            // Mark the consignment when the entire consignment supply has been released
            if (remainingSupply == _amount) consignment.released = true;
            consignment.releasedSupply = consignment.releasedSupply + _amount;

            // Transfer a balance of the token from the MarketController to the recipient
            IERC1155Upgradeable(consignment.tokenAddress).safeTransferFrom(
                address(this),
                _releaseTo,
                consignment.tokenId,
                _amount,
                new bytes(0x0)
            );

        } else {

            // Mark the single-token consignment released
            consignment.released = true;
            consignment.releasedSupply = consignment.releasedSupply + _amount;

            // Transfer the token from the MarketController to the recipient
            IERC721Upgradeable(consignment.tokenAddress).safeTransferFrom(
                address(this),
                _releaseTo,
                consignment.tokenId
            );

        }

        // Notify watchers about state change
        emit ConsignmentReleased(consignment.id, _amount, _releaseTo);

    }

    /**
     * @notice Clears the pending payout value of a consignment
     *
     * Emits a ConsignmentPayoutSet event.
     *
     * Reverts if:
     *  - caller is does not have MARKET_HANDLER role.
     *  - consignment doesn't exist
     *
     * @param _consignmentId - the id of the consignment
     * @param _amount - the amount of that the consignment's pendingPayout must be set to
     */
    function setConsignmentPendingPayout(uint256 _consignmentId, uint256 _amount)
    external
    override
    onlyRole(MARKET_HANDLER)
    consignmentExists(_consignmentId)
    {
        MarketControllerLib.MarketControllerStorage storage mcs = MarketControllerLib.marketControllerStorage();

        // Get the consignment into memory
        Consignment storage consignment = mcs.consignments[_consignmentId];

        // Update pending payout
        consignment.pendingPayout = _amount;

        // Notify watchers about state change
        emit ConsignmentPendingPayoutSet(consignment.id, _amount);

    }

    /**
     * @notice Set the type of Escrow Ticketer to be used for a consignment
     *
     * Default escrow ticketer is Ticketer.Lots. This only needs to be called
     * if overriding to Ticketer.Items for a given consignment.
     *
     * Emits a ConsignmentTicketerSet event.
     *
     * Reverts if consignment doesn't exist     *
     *
     * @param _consignmentId - the id of the consignment
     * @param _ticketerType - the type of ticketer to use. See: {SeenTypes.Ticketer}
     */
    function setConsignmentTicketer(uint256 _consignmentId, Ticketer _ticketerType)
    external
    override
    onlyRole(ESCROW_AGENT)
    consignmentExists(_consignmentId)
    {
        MarketControllerLib.MarketControllerStorage storage mcs = MarketControllerLib.marketControllerStorage();

        // Set the ticketer for the consignment if not different
        if (_ticketerType != mcs.consignmentTicketers[_consignmentId]) {

            // Set the ticketer for the consignment
            mcs.consignmentTicketers[_consignmentId] = _ticketerType;

            // Notify listeners of state change
            emit ConsignmentTicketerChanged(_consignmentId, _ticketerType);

        }
    }

    /**
     * @notice Set a custom fee percentage on a consignment (e.g. for "official" SEEN x Artist drops)
     *
     * Default escrow ticketer is Ticketer.Lots. This only needs to be called
     * if overriding to Ticketer.Items for a given consignment.
     *
     * Emits a ConsignmentFeeChanged event.
     *
     * Reverts if:
     * - consignment doesn't exist
     * - _customFeePercentageBasisPoints is more than 10000
     *
     * @param _consignmentId - the id of the consignment
     * @param _customFeePercentageBasisPoints - the custom fee percentage basis points to use
     *
     * N.B. _customFeePercentageBasisPoints percentage value as an unsigned int by multiplying the percentage by 100:
     * e.g, 1.75% = 175, 100% = 10000
     */
    function setConsignmentCustomFee(uint256 _consignmentId, uint16 _customFeePercentageBasisPoints)
    external
    override
    onlyRole(ADMIN)
    {

        MarketControllerLib.MarketControllerStorage storage mcs = MarketControllerLib.marketControllerStorage();

        // Get the consignment into memory
        Consignment storage consignment = mcs.consignments[_consignmentId];

        // Ensure the consignment exists, has not been released and that basis points don't exceed 10000
        // Rolled into one require due to contract size being near max
        require(!consignment.released && (_customFeePercentageBasisPoints <= 10000) && (_consignmentId < mcs.nextConsignment), "Consignment released or nonexistent, or basisPoints over 10000");

        consignment.customFeePercentageBasisPoints = _customFeePercentageBasisPoints;

        emit ConsignmentFeeChanged(consignment.id, _customFeePercentageBasisPoints);
    }

}