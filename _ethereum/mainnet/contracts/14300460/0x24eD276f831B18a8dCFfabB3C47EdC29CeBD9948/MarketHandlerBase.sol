// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "./IERC20Upgradeable.sol";
import "./IMarketController.sol";
import "./IMarketHandler.sol";
import "./ISeenHausNFT.sol";
import "./SeenConstants.sol";
import "./IERC2981.sol";
import "./SeenTypes.sol";
import "./MarketHandlerLib.sol";

/**
 * @title MarketHandlerBase
 *
 * @notice Provides base functionality for common actions taken by market handlers.
 *
 * @author Cliff Hall <cliff@futurescale.com> (https://twitter.com/seaofarrows)
 */
abstract contract MarketHandlerBase is IMarketHandler, SeenTypes, SeenConstants {

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

    /**
     * @dev Modifier that checks that the caller has a specific role or is a consignor.
     *
     * Reverts if caller doesn't have role or is not consignor.
     *
     * See: {AccessController.hasRole}
     */
    modifier onlyRoleOrConsignor(bytes32 _role, uint256 _consignmentId) {
        DiamondLib.DiamondStorage storage ds = DiamondLib.diamondStorage();
        require(ds.accessController.hasRole(_role, msg.sender) || getMarketController().getConsignor(_consignmentId) == msg.sender, "Caller doesn't have role or is not consignor");
        _;
    }

    /**
     * @dev Function that checks that the caller has a specific role.
     *
     * Reverts if caller doesn't have role.
     *
     * See: {AccessController.hasRole}
     */
    function checkHasRole(address _address, bytes32 _role) internal view returns (bool) {
        DiamondLib.DiamondStorage storage ds = DiamondLib.diamondStorage();
        return ds.accessController.hasRole(_role, _address);
    }

    /**
     * @notice Gets the address of the Seen.Haus MarketController contract.
     *
     * @return marketController - the address of the MarketController contract
     */
    function getMarketController()
    internal
    view
    returns(IMarketController marketController)
    {
        return IMarketController(address(this));
    }

    /**
     * @notice Sets the audience for a consignment at sale or auction.
     *
     * Emits an AudienceChanged event.
     *
     * @param _consignmentId - the id of the consignment
     * @param _audience - the new audience for the consignment
     */
    function setAudience(uint256 _consignmentId, Audience _audience)
    internal
    {
        MarketHandlerLib.MarketHandlerStorage storage mhs = MarketHandlerLib.marketHandlerStorage();

        // Set the new audience
        mhs.audiences[_consignmentId] = _audience;

        // Notify listeners of state change
        emit AudienceChanged(_consignmentId, _audience);

    }

    /**
     * @notice Check if the caller is a Staker.
     *
     * @return status - true if caller's xSEEN ERC-20 balance is non-zero.
     */
    function isStaker()
    internal
    view
    returns (bool status)
    {
        IMarketController marketController = getMarketController();
        status = IERC20Upgradeable(marketController.getStaking()).balanceOf(msg.sender) > 0;
    }

    /**
     * @notice Check if the caller is a VIP Staker.
     *
     * See {MarketController:vipStakerAmount}
     *
     * @return status - true if caller's xSEEN ERC-20 balance is at least equal to the VIP Staker Amount.
     */
    function isVipStaker()
    internal
    view
    returns (bool status)
    {
        IMarketController marketController = getMarketController();
        status = IERC20Upgradeable(marketController.getStaking()).balanceOf(msg.sender) >= marketController.getVipStakerAmount();
    }

    /**
     * @notice Modifier that checks that caller is in consignment's audience
     *
     * Reverts if user is not in consignment's audience
     */
    modifier onlyAudienceMember(uint256 _consignmentId) {
        MarketHandlerLib.MarketHandlerStorage storage mhs = MarketHandlerLib.marketHandlerStorage();
        Audience audience = mhs.audiences[_consignmentId];
        if (audience != Audience.Open) {
            if (audience == Audience.Staker) {
                require(isStaker());
            } else if (audience == Audience.VipStaker) {
                require(isVipStaker());
            }
        }
        _;
    }

    /**
     * @dev Modifier that checks that the caller is the consignor
     *
     * Reverts if caller isn't the consignor
     *
     * See: {MarketController.getConsignor}
     */
    modifier onlyConsignor(uint256 _consignmentId) {

        // Make sure the caller is the consignor
        require(getMarketController().getConsignor(_consignmentId) == msg.sender, "Caller is not consignor");
        _;
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

    /**
     * @notice Deduct and pay royalties on sold secondary market consignments.
     *
     * Does nothing is this is a primary market sale.
     *
     * If the consigned item's contract supports NFT Royalty Standard EIP-2981,
     * it is queried for the expected royalty amount and recipient.
     *
     * Deducts royalty and pays to recipient:
     * - entire expected amount, if below or equal to the marketplace's maximum royalty percentage
     * - the marketplace's maximum royalty percentage See: {MarketController.maxRoyaltyPercentage}
     *
     * Emits a RoyaltyDisbursed event with the amount actually paid.
     *
     * @param _consignment - the consigned item
     * @param _grossSale - the gross sale amount
     *
     * @return net - the net amount of the sale after the royalty has been paid
     */
    function deductRoyalties(Consignment memory _consignment, uint256 _grossSale)
    internal
    returns (uint256 net)
    {
        // Only pay royalties on secondary market sales
        uint256 royaltyAmount = 0;
        if (_consignment.market == Market.Secondary) {
            // Determine if NFT contract supports NFT Royalty Standard EIP-2981
            try IERC165Upgradeable(_consignment.tokenAddress).supportsInterface(type(IERC2981).interfaceId) returns (bool supported) {

                // If so, find out the who to pay and how much
                if (supported) {

                    // Get the MarketController
                    IMarketController marketController = getMarketController();

                    // Get the royalty recipient and expected payment
                    (address recipient, uint256 expected) = IERC2981(_consignment.tokenAddress).royaltyInfo(_consignment.tokenId, _grossSale);

                    // Determine the max royalty we will pay
                    uint256 maxRoyalty = getPercentageOf(_grossSale, marketController.getMaxRoyaltyPercentage());

                    // If a royalty is expected...
                    if (expected > 0) {

                        // Lets pay, but only up to our platform policy maximum
                        royaltyAmount = (expected <= maxRoyalty) ? expected : maxRoyalty;
                        sendValueOrCreditAccount(payable(recipient), royaltyAmount);

                        // Notify listeners of payment
                        emit RoyaltyDisbursed(_consignment.id, recipient, royaltyAmount);
                    }

                }

            // Any case where the check for interface support fails can be ignored
            } catch Error(string memory) {
            } catch (bytes memory) {
            }

        }

        // Return the net amount after royalty deduction
        net = _grossSale - royaltyAmount;
    }

    /**
     * @notice Deduct and pay escrow agent fees on sold physical secondary market consignments.
     *
     * Does nothing if this is a primary market sale.
     *
     * Deducts escrow agent fee and pays to consignor
     * - entire expected amount
     *
     * Emits a EscrowAgentFeeDisbursed event with the amount actually paid.
     *
     * @param _consignment - the consigned item
     * @param _grossSale - the gross sale amount
     * @param _netAfterRoyalties - the funds left to be distributed
     *
     * @return net - the net amount of the sale after the royalty has been paid
     */
    function deductEscrowAgentFee(Consignment memory _consignment, uint256 _grossSale, uint256 _netAfterRoyalties)
    internal
    returns (uint256 net)
    {
        // Only pay royalties on secondary market sales
        uint256 escrowAgentFeeAmount = 0;
        if (_consignment.market == Market.Secondary) {
            // Get the MarketController
            IMarketController marketController = getMarketController();
            address consignor = marketController.getConsignor(_consignment.id);
            if(consignor != _consignment.seller) {
                uint16 escrowAgentBasisPoints = marketController.getEscrowAgentFeeBasisPoints(consignor);
                if(escrowAgentBasisPoints > 0) {
                    // Determine if consignment is physical
                    address nft = marketController.getNft();
                    if (nft == _consignment.tokenAddress && ISeenHausNFT(nft).isPhysical(_consignment.tokenId)) {
                        // Consignor is not seller, consigner has a positive escrowAgentBasisPoints value, consignment is of a physical item
                        // Therefore, pay consignor the escrow agent fees
                        escrowAgentFeeAmount = getPercentageOf(_grossSale, escrowAgentBasisPoints);

                        // If escrow agent fee is expected...
                        if (escrowAgentFeeAmount > 0) {
                            require(escrowAgentFeeAmount <= _netAfterRoyalties, "escrowAgentFeeAmount exceeds remaining funds");
                            sendValueOrCreditAccount(payable(consignor), escrowAgentFeeAmount);
                            // Notify listeners of payment
                            emit EscrowAgentFeeDisbursed(_consignment.id, consignor, escrowAgentFeeAmount);
                        }
                    }
                }
            }
        }

        // Return the net amount after royalty deduction
        net = _netAfterRoyalties - escrowAgentFeeAmount;
    }

    /**
     * @notice Deduct and pay fee on a sold consignment.
     *
     * Deducts marketplace fee and pays:
     * - Half to the staking contract
     * - Half to the multisig contract
     *
     * Emits a FeeDisbursed event for staking payment.
     * Emits a FeeDisbursed event for multisig payment.
     *
     * @param _consignment - the consigned item
     * @param _grossSale - the gross sale amount
     * @param _netAmount - the net amount after royalties (total remaining to be distributed as part of payout process)
     *
     * @return payout - the payout amount for the seller
     */
    function deductFee(Consignment memory _consignment, uint256 _grossSale, uint256 _netAmount)
    internal
    returns (uint256 payout)
    {
        // Get the MarketController
        IMarketController marketController = getMarketController();

        // With the net after royalties, calculate and split
        // the auction fee between SEEN staking and multisig,
        uint256 feeAmount;
        if(_consignment.customFeePercentageBasisPoints > 0) {
            feeAmount = getPercentageOf(_grossSale, _consignment.customFeePercentageBasisPoints);
        } else {
            feeAmount = getPercentageOf(_grossSale, marketController.getFeePercentage(_consignment.market));
        }
        require(feeAmount <= _netAmount, "feeAmount exceeds remaining funds");
        uint256 splitStaking = feeAmount / 2;
        uint256 splitMultisig = feeAmount - splitStaking;
        address payable staking = marketController.getStaking();
        address payable multisig = marketController.getMultisig();
        sendValueOrCreditAccount(staking, splitStaking);
        sendValueOrCreditAccount(multisig, splitMultisig);

        // Return the seller payout amount after fee deduction
        payout = _netAmount - feeAmount;

        // Notify listeners of payment
        emit FeeDisbursed(_consignment.id, staking, splitStaking);
        emit FeeDisbursed(_consignment.id, multisig, splitMultisig);
    }

    /**
     * @notice Disburse funds for a sale or auction, primary or secondary.
     *
     * Disburses funds in this order
     * - Pays any necessary royalties first. See {deductRoyalties}
     * - Deducts and distributes marketplace fee. See {deductFee}
     * - Pays the remaining amount to the seller.
     *
     * Emits a PayoutDisbursed event on success.
     *
     * @param _consignmentId - the id of the consignment being sold
     * @param _saleAmount - the gross sale amount
     */
    function disburseFunds(uint256 _consignmentId, uint256 _saleAmount)
    internal
    {
        // Get the MarketController
        IMarketController marketController = getMarketController();

        // Get consignment
        SeenTypes.Consignment memory consignment = marketController.getConsignment(_consignmentId);

        // Pay royalties if needed
        uint256 netAfterRoyalties = deductRoyalties(consignment, _saleAmount);

        // Pay escrow agent fees if needed
        uint256 netAfterEscrowAgentFees = deductEscrowAgentFee(consignment, _saleAmount, netAfterRoyalties);

        // Pay marketplace fee
        uint256 payout = deductFee(consignment, _saleAmount, netAfterEscrowAgentFees);

        // Pay seller
        sendValueOrCreditAccount(consignment.seller, payout);

        // Notify listeners of payment
        emit PayoutDisbursed(_consignmentId, consignment.seller, payout);
    }

    /**
     * @notice Attempts an ETH transfer, else adds a pull-able credit
     *
     * In cases where ETH is unable to be transferred to a particular address
     * either due to malicious agents or bugs in receiver addresses
     * the payout process should not fail for all parties involved 
     * (or funds can become stuck for benevolent parties)
     *
     * @param _recipient - the recipient of the transfer
     * @param _value - the transfer value
     */
    function sendValueOrCreditAccount(address payable _recipient, uint256 _value)
    internal
    {
        // Attempt to send funds to recipient
        require(address(this).balance >= _value);
        (bool success, ) = _recipient.call{value: _value}("");
        if(!success) {
            // Credit the account
            MarketHandlerLib.MarketHandlerStorage storage mhs = MarketHandlerLib.marketHandlerStorage();
            mhs.addressToEthCredit[_recipient] += _value;
            emit EthCredited(_recipient, _value);
        }
    }

}