// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import "./MechanicMintManagerClientUpgradeable.sol";
import "./IEditionCollection.sol";
import "./IERC721GeneralSupplyMetadata.sol";
import "./PackedPrices.sol";

import "./EnumerableSet.sol";
import "./UUPSUpgradeable.sol";

/**
 * @notice Highlight's bespoke Dutch Auction mint mechanic (rebates, discrete prices, not continuous)
 * @dev Processes ether based auctions only
 *      DPP = Dynamic Price Period
 *      FPP = Fixed Price Period
 * @author highlight.xyz
 */
contract DiscreteDutchAuctionMechanic is MechanicMintManagerClientUpgradeable, UUPSUpgradeable {
    using EnumerableSet for EnumerableSet.Bytes32Set;

    /**
     * @notice Throw when an action is unauthorized
     */
    error Unauthorized();

    /**
     * @notice Throw when a vector is attempted to be created or updated with an invalid configuration
     */
    error InvalidVectorConfig();

    /**
     * @notice Throw when a vector is attempted to be updated or deleted at an invalid time
     */
    error InvalidUpdate();

    /**
     * @notice Throw when a vector is already created with a mechanic vector ID
     */
    error VectorAlreadyCreated();

    /**
     * @notice Throw when it is invalid to mint on a vector
     */
    error InvalidMint();

    /**
     * @notice Throw when it is invalid to withdraw funds from a DPP
     */
    error InvalidDPPFundsWithdrawl();

    /**
     * @notice Throw when it is invalid to collect a rebate
     */
    error InvalidRebate();

    /**
     * @notice Throw when a collector isn't owed any rebates
     */
    error CollectorNotOwedRebate();

    /**
     * @notice Throw when the contract fails to send ether to a payment recipient
     */
    error EtherSendFailed();

    /**
     * @notice Throw when the transaction sender has sent an invalid payment amount during a mint
     */
    error InvalidPaymentAmount();

    /**
     * @notice Vector data
     * @dev Guiding uint typing:
     *      log(periodDuration) <= log(timestamps)
     *      log(numTokensBought) <= log(maxUser)
     *      log(numToMint) <= log(numTokensBought)
     *      log(maxUser) <= log(maxTotal)
     *      log(lowestPriceSoldAtIndex) < log(numPrices)
     *      log(prices[i]) <= log(totalSales)
     *      log(totalPosted) <= log(totalSales)
     *      log(prices[i]) <= log(totalPosted)
     *      log(numTokensbought) + log(totalPosted) <= 256
     */
    struct DutchAuctionVector {
        // slot 0
        uint48 startTimestamp;
        uint48 endTimestamp;
        uint32 periodDuration;
        uint32 maxUserClaimableViaVector;
        uint48 maxTotalClaimableViaVector;
        uint48 currentSupply;
        // slot 1
        uint32 lowestPriceSoldAtIndex;
        uint32 tokenLimitPerTx;
        uint32 numPrices;
        address payable paymentRecipient;
        // slot 2
        uint240 totalSales;
        uint8 bytesPerPrice;
        bool auctionExhausted;
        bool payeeRevenueHasBeenWithdrawn;
    }

    /**
     * @notice Config used to control updating of fields in DutchAuctionVector
     */
    struct DutchAuctionVectorUpdateConfig {
        bool updateStartTimestamp;
        bool updateEndTimestamp;
        bool updatePeriodDuration;
        bool updateMaxUserClaimableViaVector;
        bool updateMaxTotalClaimableViaVector;
        bool updateTokenLimitPerTx;
        bool updatePaymentRecipient;
        bool updatePrices;
    }

    /**
     * @notice User purchase info per dutch auction per user
     * @param numTokensBought Number of tokens bought in the dutch auction
     * @param numRebates Number of times the user has requested a rebate
     * @param totalPosted Total amount paid by buyer minus rebates sent
     */
    struct UserPurchaseInfo {
        uint32 numTokensBought;
        uint24 numRebates;
        uint200 totalPosted;
    }

    /**
     * @notice Stores dutch auctions, indexed by global mechanic vector id
     */
    mapping(bytes32 => DutchAuctionVector) private vector;

    /**
     * @notice Stores dutch auction prices (packed), indexed by global mechanic vector id
     */
    mapping(bytes32 => bytes) private vectorPackedPrices;

    /**
     * @notice Stores user purchase info, per user per auction
     */
    mapping(bytes32 => mapping(address => UserPurchaseInfo)) public userPurchaseInfo;

    /**
     * @notice Emitted when a dutch auction is created
     */
    event DiscreteDutchAuctionCreated(bytes32 indexed mechanicVectorId);

    /**
     * @notice Emitted when a dutch auction is updated
     */
    event DiscreteDutchAuctionUpdated(bytes32 indexed mechanicVectorId);

    /**
     * @notice Emitted when a number of tokens are minted via a dutch auction
     */
    event DiscreteDutchAuctionMint(
        bytes32 indexed mechanicVectorId,
        address indexed recipient,
        uint200 pricePerToken,
        uint48 numMinted
    );

    /**
     * @notice Emitted when a collector receives a rebate
     * @param mechanicVectorId Mechanic vector ID
     * @param collector Collector receiving rebate
     * @param rebate The amount of ETH returned to the collector
     * @param currentPricePerNft The current price per NFT at the time of rebate
     */
    event DiscreteDutchAuctionCollectorRebate(
        bytes32 indexed mechanicVectorId,
        address indexed collector,
        uint200 rebate,
        uint200 currentPricePerNft
    );

    /**
     * @notice Emitted when the DPP revenue is withdrawn to the payment recipient once the auction hits the FPP.
     * @dev NOTE - amount of funds withdrawn may include sales from the FPP. After funds are withdrawn, payment goes
     *           straight to the payment recipient on mint
     * @param mechanicVectorId Mechanic vector ID
     * @param paymentRecipient Payment recipient at time of withdrawal
     * @param clearingPrice The final clearing price per NFT
     * @param currentSupply The number of minted tokens to withdraw sales for
     */
    event DiscreteDutchAuctionDPPFundsWithdrawn(
        bytes32 indexed mechanicVectorId,
        address indexed paymentRecipient,
        uint200 clearingPrice,
        uint48 currentSupply
    );

    /**
     * @notice Initialize mechanic contract
     * @param _mintManager Mint manager address
     * @param platform Platform owning the contract
     */
    function initialize(address _mintManager, address platform) external initializer {
        __MechanicMintManagerClientUpgradeable_initialize(_mintManager, platform);
    }

    /**
     * @notice Create a dutch auction vector
     * @param mechanicVectorId Global mechanic vector ID
     * @param vectorData Vector data, to be deserialized into dutch auction vector data
     */
    function createVector(bytes32 mechanicVectorId, bytes memory vectorData) external onlyMintManager {
        // precaution, although MintManager tightly controls creation and prevents double creation
        if (vector[mechanicVectorId].periodDuration != 0) {
            _revert(VectorAlreadyCreated.selector);
        }
        (
            uint48 startTimestamp,
            uint48 endTimestamp,
            uint32 periodDuration,
            uint32 maxUserClaimableViaVector,
            uint48 maxTotalClaimableViaVector,
            uint32 tokenLimitPerTx,
            uint32 numPrices,
            uint8 bytesPerPrice,
            address paymentRecipient,
            bytes memory packedPrices
        ) = abi.decode(vectorData, (uint48, uint48, uint32, uint32, uint48, uint32, uint32, uint8, address, bytes));

        DutchAuctionVector memory _vector = DutchAuctionVector(
            startTimestamp == 0 ? uint48(block.timestamp) : startTimestamp,
            endTimestamp,
            periodDuration,
            maxUserClaimableViaVector,
            maxTotalClaimableViaVector,
            0,
            0,
            tokenLimitPerTx,
            numPrices,
            payable(paymentRecipient),
            0,
            bytesPerPrice,
            false,
            false
        );

        _validateVectorConfig(_vector, packedPrices, true);

        vector[mechanicVectorId] = _vector;
        vectorPackedPrices[mechanicVectorId] = packedPrices;

        emit DiscreteDutchAuctionCreated(mechanicVectorId);
    }

    /* solhint-disable code-complexity */
    /**
     * @notice Update a dutch auction vector
     * @param mechanicVectorId Global mechanic vector ID
     * @param newVector New vector fields
     * @param updateConfig Config denoting what fields on vector to update
     */
    function updateVector(
        bytes32 mechanicVectorId,
        DutchAuctionVector calldata newVector,
        bytes calldata newPackedPrices,
        DutchAuctionVectorUpdateConfig calldata updateConfig
    ) external {
        MechanicVectorMetadata memory metadata = _getMechanicVectorMetadata(mechanicVectorId);
        if (
            metadata.contractAddress != msg.sender && OwnableUpgradeable(metadata.contractAddress).owner() != msg.sender
        ) {
            _revert(Unauthorized.selector);
        }
        DutchAuctionVector memory currentVector = vector[mechanicVectorId];

        // after first token has been minted, cannot update: prices, period, start time, max total claimable via vector
        if (
            currentVector.currentSupply > 0 &&
            (updateConfig.updatePrices ||
                updateConfig.updatePeriodDuration ||
                updateConfig.updateStartTimestamp ||
                updateConfig.updateMaxTotalClaimableViaVector)
        ) {
            _revert(InvalidUpdate.selector);
        }

        // construct end state of vector with updates applied, then validate
        if (updateConfig.updateStartTimestamp) {
            currentVector.startTimestamp = newVector.startTimestamp == 0
                ? uint48(block.timestamp)
                : newVector.startTimestamp;
        }
        if (updateConfig.updateEndTimestamp) {
            currentVector.endTimestamp = newVector.endTimestamp;
        }
        if (updateConfig.updatePeriodDuration) {
            currentVector.periodDuration = newVector.periodDuration;
        }
        if (updateConfig.updateMaxUserClaimableViaVector) {
            currentVector.maxUserClaimableViaVector = newVector.maxUserClaimableViaVector;
        }
        if (updateConfig.updateMaxTotalClaimableViaVector) {
            currentVector.maxTotalClaimableViaVector = newVector.maxTotalClaimableViaVector;
        }
        if (updateConfig.updateTokenLimitPerTx) {
            currentVector.tokenLimitPerTx = newVector.tokenLimitPerTx;
        }
        if (updateConfig.updatePaymentRecipient) {
            currentVector.paymentRecipient = newVector.paymentRecipient;
        }
        if (updateConfig.updatePrices) {
            currentVector.bytesPerPrice = newVector.bytesPerPrice;
            currentVector.numPrices = newVector.numPrices;
        }

        _validateVectorConfig(currentVector, newPackedPrices, updateConfig.updatePrices);

        // rather than updating entire vector, update per-field
        if (updateConfig.updateStartTimestamp) {
            vector[mechanicVectorId].startTimestamp = currentVector.startTimestamp;
        }
        if (updateConfig.updateEndTimestamp) {
            vector[mechanicVectorId].endTimestamp = currentVector.endTimestamp;
        }
        if (updateConfig.updatePeriodDuration) {
            vector[mechanicVectorId].periodDuration = currentVector.periodDuration;
        }
        if (updateConfig.updateMaxUserClaimableViaVector) {
            vector[mechanicVectorId].maxUserClaimableViaVector = currentVector.maxUserClaimableViaVector;
        }
        if (updateConfig.updateMaxTotalClaimableViaVector) {
            vector[mechanicVectorId].maxTotalClaimableViaVector = currentVector.maxTotalClaimableViaVector;
        }
        if (updateConfig.updateTokenLimitPerTx) {
            vector[mechanicVectorId].tokenLimitPerTx = currentVector.tokenLimitPerTx;
        }
        if (updateConfig.updatePaymentRecipient) {
            vector[mechanicVectorId].paymentRecipient = currentVector.paymentRecipient;
        }
        if (updateConfig.updatePrices) {
            vectorPackedPrices[mechanicVectorId] = newPackedPrices;
            vector[mechanicVectorId].bytesPerPrice = currentVector.bytesPerPrice;
            vector[mechanicVectorId].numPrices = currentVector.numPrices;
        }

        emit DiscreteDutchAuctionUpdated(mechanicVectorId);
    }

    /* solhint-enable code-complexity */

    /**
     * @notice See {IMechanic-processNumMint}
     */
    function processNumMint(
        bytes32 mechanicVectorId,
        address recipient,
        uint32 numToMint,
        MechanicVectorMetadata calldata mechanicVectorMetadata,
        bytes calldata data
    ) external payable onlyMintManager {
        _processMint(mechanicVectorId, recipient, numToMint);
    }

    /**
     * @notice See {IMechanic-processChooseMint}
     */
    function processChooseMint(
        bytes32 mechanicVectorId,
        address recipient,
        uint256[] calldata tokenIds,
        MechanicVectorMetadata calldata mechanicVectorMetadata,
        bytes calldata data
    ) external payable onlyMintManager {
        _processMint(mechanicVectorId, recipient, uint32(tokenIds.length));
    }

    /**
     * @notice Rebate a collector any rebates they're eligible for
     * @param mechanicVectorId Mechanic vector ID
     * @param collector Collector to send rebates to
     */
    function rebateCollector(bytes32 mechanicVectorId, address payable collector) external {
        DutchAuctionVector memory _vector = vector[mechanicVectorId];
        UserPurchaseInfo memory _userPurchaseInfo = userPurchaseInfo[mechanicVectorId][collector];

        if (_vector.currentSupply == 0) {
            _revert(InvalidRebate.selector);
        }
        bool _auctionExhausted = _vector.auctionExhausted;
        if (!_auctionExhausted) {
            _auctionExhausted = _isAuctionExhausted(
                mechanicVectorId,
                _vector.currentSupply,
                _vector.maxTotalClaimableViaVector
            );
            if (_auctionExhausted) {
                vector[mechanicVectorId].auctionExhausted = true;
            }
        }

        // rebate collector at the price:
        // - lowest price sold at if auction is exhausted (vector sold out or collection sold out)
        // - current price otherwise
        uint200 currentPrice = PackedPrices.priceAt(
            vectorPackedPrices[mechanicVectorId],
            _vector.bytesPerPrice,
            _auctionExhausted
                ? _vector.lowestPriceSoldAtIndex
                : _calculatePriceIndex(_vector.startTimestamp, _vector.periodDuration, _vector.numPrices)
        );
        uint200 currentPriceObligation = _userPurchaseInfo.numTokensBought * currentPrice;
        uint200 amountOwed = _userPurchaseInfo.totalPosted - currentPriceObligation;

        if (amountOwed == 0) {
            _revert(CollectorNotOwedRebate.selector);
        }

        userPurchaseInfo[mechanicVectorId][collector].totalPosted = currentPriceObligation;
        userPurchaseInfo[mechanicVectorId][collector].numRebates = _userPurchaseInfo.numRebates + 1;

        (bool sentToCollector, bytes memory data) = collector.call{ value: amountOwed }("");
        if (!sentToCollector) {
            _revert(EtherSendFailed.selector);
        }

        emit DiscreteDutchAuctionCollectorRebate(mechanicVectorId, collector, amountOwed, currentPrice);
    }

    /**
     * @notice Withdraw funds collected through the dynamic period of a dutch auction
     * @param mechanicVectorId Mechanic vector ID
     */
    function withdrawDPPFunds(bytes32 mechanicVectorId) external {
        // all slots are used, so load entire object from storage
        DutchAuctionVector memory _vector = vector[mechanicVectorId];

        if (_vector.payeeRevenueHasBeenWithdrawn || _vector.currentSupply == 0) {
            _revert(InvalidDPPFundsWithdrawl.selector);
        }
        bool _auctionExhausted = _vector.auctionExhausted;
        if (!_auctionExhausted) {
            _auctionExhausted = _isAuctionExhausted(
                mechanicVectorId,
                _vector.currentSupply,
                _vector.maxTotalClaimableViaVector
            );
            if (_auctionExhausted) {
                vector[mechanicVectorId].auctionExhausted = true;
            }
        }
        uint32 priceIndex = _auctionExhausted
            ? _vector.lowestPriceSoldAtIndex
            : _calculatePriceIndex(_vector.startTimestamp, _vector.periodDuration, _vector.numPrices);

        // if any of the following 3 are met, DPP funds can be withdrawn:
        //  - auction is in FPP
        //  - maxTotalClaimableViaVector is reached
        //  - all tokens have been minted on collection (outside of vector knowledge)
        if (!_auctionExhausted && !_auctionIsInFPP(_vector.currentSupply, priceIndex, _vector.numPrices)) {
            _revert(InvalidDPPFundsWithdrawl.selector);
        }

        vector[mechanicVectorId].payeeRevenueHasBeenWithdrawn = true;

        uint200 clearingPrice = PackedPrices.priceAt(
            vectorPackedPrices[mechanicVectorId],
            _vector.bytesPerPrice,
            priceIndex
        );
        uint200 totalRefund = _vector.currentSupply * clearingPrice;
        // precaution: protect against pulling out more than total sales ->
        // guards against bad actor pulling out more via
        // funds collection + rebate price ascending setup (theoretically not possible)
        if (totalRefund > _vector.totalSales) {
            _revert(InvalidDPPFundsWithdrawl.selector);
        }

        (bool sentToPaymentRecipient, bytes memory data) = _vector.paymentRecipient.call{ value: totalRefund }("");
        if (!sentToPaymentRecipient) {
            _revert(EtherSendFailed.selector);
        }

        emit DiscreteDutchAuctionDPPFundsWithdrawn(
            mechanicVectorId,
            _vector.paymentRecipient,
            clearingPrice,
            _vector.currentSupply
        );
    }

    /**
     * @notice Get how much of a rebate a user is owed
     * @param mechanicVectorId Mechanic vector ID
     * @param user User to get rebate information for
     */
    function getUserInfo(
        bytes32 mechanicVectorId,
        address user
    ) external view returns (uint256 rebate, UserPurchaseInfo memory) {
        DutchAuctionVector memory _vector = vector[mechanicVectorId];
        UserPurchaseInfo memory _userPurchaseInfo = userPurchaseInfo[mechanicVectorId][user];

        if (_vector.currentSupply == 0) {
            return (0, _userPurchaseInfo);
        }

        // rebate collector at the price:
        // - lowest price sold at if vector is sold out or collection is sold out
        // - current price otherwise
        uint200 currentPrice = PackedPrices.priceAt(
            vectorPackedPrices[mechanicVectorId],
            _vector.bytesPerPrice,
            _isAuctionExhausted(mechanicVectorId, _vector.currentSupply, _vector.maxTotalClaimableViaVector)
                ? _vector.lowestPriceSoldAtIndex
                : _calculatePriceIndex(_vector.startTimestamp, _vector.periodDuration, _vector.numPrices)
        );
        uint200 currentPriceObligation = _userPurchaseInfo.numTokensBought * currentPrice;
        uint256 amountOwed = uint256(_userPurchaseInfo.totalPosted - currentPriceObligation);

        return (amountOwed, _userPurchaseInfo);
    }

    /**
     * @notice Get how much is owed to the payment recipient (currently)
     * @param mechanicVectorId Mechanic vector ID
     * @param escrowFunds Amount owed to the creator currently
     * @param amountFinalized Whether this is the actual amount that will be owed (will decrease until the auction ends)
     */
    function getPayeePotentialEscrowedFunds(
        bytes32 mechanicVectorId
    ) external view returns (uint256 escrowFunds, bool amountFinalized) {
        return _getPayeePotentialEscrowedFunds(mechanicVectorId);
    }

    /**
     * @notice Get raw vector data
     * @param mechanicVectorId Mechanic vector ID
     */
    function getRawVector(
        bytes32 mechanicVectorId
    ) external view returns (DutchAuctionVector memory _vector, bytes memory packedPrices) {
        _vector = vector[mechanicVectorId];
        packedPrices = vectorPackedPrices[mechanicVectorId];
    }

    /**
     * @notice Get a vector's full state, including the refund currently owed to the creator and human-readable prices
     * @param mechanicVectorId Mechanic vector ID
     */
    function getVectorState(
        bytes32 mechanicVectorId
    )
        external
        view
        returns (
            DutchAuctionVector memory _vector,
            uint200[] memory prices,
            uint200 currentPrice,
            uint256 payeePotentialEscrowedFunds,
            uint256 collectionSupply,
            uint256 collectionSize,
            bool escrowedFundsAmountFinalized,
            bool auctionExhausted,
            bool auctionInFPP
        )
    {
        _vector = vector[mechanicVectorId];
        (payeePotentialEscrowedFunds, escrowedFundsAmountFinalized) = _getPayeePotentialEscrowedFunds(mechanicVectorId);
        (collectionSupply, collectionSize) = _collectionSupplyAndSize(mechanicVectorId);
        auctionExhausted =
            _vector.auctionExhausted ||
            _isAuctionExhausted(mechanicVectorId, _vector.currentSupply, _vector.maxTotalClaimableViaVector);
        uint32 priceIndex = auctionExhausted
            ? _vector.lowestPriceSoldAtIndex
            : _calculatePriceIndex(_vector.startTimestamp, _vector.periodDuration, _vector.numPrices);
        currentPrice = PackedPrices.priceAt(vectorPackedPrices[mechanicVectorId], _vector.bytesPerPrice, priceIndex);
        auctionInFPP = _auctionIsInFPP(_vector.currentSupply, priceIndex, _vector.numPrices);
        prices = PackedPrices.unpack(vectorPackedPrices[mechanicVectorId], _vector.bytesPerPrice, _vector.numPrices);
    }

    /* solhint-disable no-empty-blocks */
    /**
     * @notice Limit upgrades of contract to DiscreteDutchAuctionMechanic owner
     * @param // New implementation address
     */
    function _authorizeUpgrade(address) internal override onlyOwner {}

    /**
     * @notice Process mint logic common through sequential and collector's choice based mints
     * @param mechanicVectorId Mechanic vector ID
     * @param recipient Mint recipient
     * @param numToMint Number of tokens to mint
     */
    function _processMint(bytes32 mechanicVectorId, address recipient, uint32 numToMint) private {
        DutchAuctionVector memory _vector = vector[mechanicVectorId];
        UserPurchaseInfo memory _userPurchaseInfo = userPurchaseInfo[mechanicVectorId][recipient];

        uint48 newSupply = _vector.currentSupply + numToMint;
        if (
            block.timestamp < _vector.startTimestamp ||
            (block.timestamp > _vector.endTimestamp && _vector.endTimestamp != 0) ||
            (_vector.maxTotalClaimableViaVector != 0 && newSupply > _vector.maxTotalClaimableViaVector) ||
            (_vector.maxUserClaimableViaVector != 0 &&
                _userPurchaseInfo.numTokensBought + numToMint > _vector.maxUserClaimableViaVector) ||
            (_vector.tokenLimitPerTx != 0 && numToMint > _vector.tokenLimitPerTx) ||
            _vector.auctionExhausted
        ) {
            _revert(InvalidMint.selector);
        }

        // can safely cast down here since the value is dependent on array length
        uint32 priceIndex = _calculatePriceIndex(_vector.startTimestamp, _vector.periodDuration, _vector.numPrices);
        uint200 price = PackedPrices.priceAt(vectorPackedPrices[mechanicVectorId], _vector.bytesPerPrice, priceIndex);
        uint200 totalPrice = price * numToMint;

        if (totalPrice > msg.value) {
            _revert(InvalidPaymentAmount.selector);
        }

        // update lowestPriceSoldAtindex, currentSupply, totalSales and user purchase info
        if (_vector.lowestPriceSoldAtIndex != priceIndex) {
            vector[mechanicVectorId].lowestPriceSoldAtIndex = priceIndex;
        }
        vector[mechanicVectorId].currentSupply = newSupply;
        vector[mechanicVectorId].totalSales = _vector.totalSales + totalPrice;
        _userPurchaseInfo.numTokensBought += numToMint;
        _userPurchaseInfo.totalPosted += uint200(msg.value); // if collector sent more, let them collect the difference
        userPurchaseInfo[mechanicVectorId][recipient] = _userPurchaseInfo;

        if (_vector.payeeRevenueHasBeenWithdrawn) {
            // send ether value to payment recipient
            (bool sentToPaymentRecipient, bytes memory data) = _vector.paymentRecipient.call{ value: totalPrice }("");
            if (!sentToPaymentRecipient) {
                _revert(EtherSendFailed.selector);
            }
        }

        emit DiscreteDutchAuctionMint(mechanicVectorId, recipient, price, numToMint);
    }

    /**
     * @notice Validate a dutch auction vector
     * @param _vector Dutch auction vector being validated
     */
    function _validateVectorConfig(
        DutchAuctionVector memory _vector,
        bytes memory packedPrices,
        bool validateIndividualPrices
    ) private {
        if (
            _vector.periodDuration == 0 ||
            _vector.paymentRecipient == address(0) ||
            _vector.numPrices < 2 ||
            _vector.bytesPerPrice > 32
        ) {
            _revert(InvalidVectorConfig.selector);
        }
        if (_vector.endTimestamp != 0) {
            // allow the last period to be truncated
            if (_vector.startTimestamp + ((_vector.numPrices - 1) * _vector.periodDuration) >= _vector.endTimestamp) {
                _revert(InvalidVectorConfig.selector);
            }
        }
        if (validateIndividualPrices) {
            if (_vector.bytesPerPrice * _vector.numPrices != packedPrices.length) {
                _revert(InvalidVectorConfig.selector);
            }
            uint200[] memory prices = PackedPrices.unpack(packedPrices, _vector.bytesPerPrice, _vector.numPrices);
            uint200 lastPrice = prices[0];
            uint256 numPrices = uint256(_vector.numPrices); // cast up into uint256 for gas savings on array check
            for (uint256 i = 1; i < _vector.numPrices; i++) {
                if (prices[i] >= lastPrice) {
                    _revert(InvalidVectorConfig.selector);
                }
                lastPrice = prices[i];
            }
        }
    }

    /**
     * @notice Get how much is owed to the payment recipient currently
     * @param mechanicVectorId Mechanic vector ID
     * @return escrowFunds + isFinalAmount
     */
    function _getPayeePotentialEscrowedFunds(bytes32 mechanicVectorId) private view returns (uint256, bool) {
        DutchAuctionVector memory _vector = vector[mechanicVectorId];

        if (_vector.payeeRevenueHasBeenWithdrawn) {
            // escrowed funds have already been withdrawn / finalized
            return (0, true);
        }
        if (_vector.currentSupply == 0) {
            return (0, false);
        }

        bool auctionExhausted = _vector.auctionExhausted ||
            _isAuctionExhausted(mechanicVectorId, _vector.currentSupply, _vector.maxTotalClaimableViaVector);
        uint32 priceIndex = auctionExhausted
            ? _vector.lowestPriceSoldAtIndex
            : _calculatePriceIndex(_vector.startTimestamp, _vector.periodDuration, _vector.numPrices);
        uint200 potentialClearingPrice = PackedPrices.priceAt(
            vectorPackedPrices[mechanicVectorId],
            _vector.bytesPerPrice,
            priceIndex
        );

        // escrowFunds is only final if auction is exhausted or in FPP
        return (
            uint256(_vector.currentSupply * potentialClearingPrice),
            (auctionExhausted || _auctionIsInFPP(_vector.currentSupply, priceIndex, _vector.numPrices))
        );
    }

    /**
     * @notice Return true if an auction has reached its max supply or if the underlying collection has
     * @param mechanicVectorId Mechanic vector ID
     * @param currentSupply Current supply minted through the vector
     * @param maxTotalClaimableViaVector Max claimable via the vector
     */
    function _isAuctionExhausted(
        bytes32 mechanicVectorId,
        uint48 currentSupply,
        uint48 maxTotalClaimableViaVector
    ) private view returns (bool) {
        if (maxTotalClaimableViaVector != 0 && currentSupply >= maxTotalClaimableViaVector) return true;
        (uint256 supply, uint256 size) = _collectionSupplyAndSize(mechanicVectorId);
        return size != 0 && supply >= size;
    }

    /**
     * @notice Returns a collection's current supply
     * @param mechanicVectorId Mechanic vector ID
     */
    function _collectionSupplyAndSize(bytes32 mechanicVectorId) private view returns (uint256 supply, uint256 size) {
        MechanicVectorMetadata memory metadata = _getMechanicVectorMetadata(mechanicVectorId);
        if (metadata.contractAddress == address(0)) {
            revert("Vector doesn't exist");
        }
        if (metadata.isEditionBased) {
            IEditionCollection.EditionDetails memory edition = IEditionCollection(metadata.contractAddress)
                .getEditionDetails(metadata.editionId);
            supply = edition.supply;
            size = edition.size;
        } else {
            // supply holds a tighter constraint (no burns), some old contracts don't have it
            try IERC721GeneralSupplyMetadata(metadata.contractAddress).supply() returns (uint256 _supply) {
                supply = _supply;
            } catch {
                supply = IERC721GeneralSupplyMetadata(metadata.contractAddress).totalSupply();
            }
            size = IERC721GeneralSupplyMetadata(metadata.contractAddress).limitSupply();
        }
    }

    /**
     * @notice Calculate what price the dutch auction is at
     * @param startTimestamp Auction start time
     * @param periodDuration Time per period
     * @param numPrices Number of prices
     */
    function _calculatePriceIndex(
        uint48 startTimestamp,
        uint32 periodDuration,
        uint32 numPrices
    ) private view returns (uint32) {
        if (block.timestamp <= startTimestamp) {
            return 0;
        }
        uint256 hypotheticalIndex = uint256((block.timestamp - startTimestamp) / periodDuration);
        if (hypotheticalIndex >= numPrices) {
            return numPrices - 1;
        } else {
            return uint32(hypotheticalIndex);
        }
    }

    /**
     * @notice Return if the auction is in the fixed price period
     * @param currentSupply Current supply of tokens minted via mechanic vector
     * @param priceIndex Index of price prices
     * @param numPrices Number of prices
     */
    function _auctionIsInFPP(uint48 currentSupply, uint256 priceIndex, uint32 numPrices) private pure returns (bool) {
        return currentSupply > 0 && priceIndex == numPrices - 1;
    }
}
