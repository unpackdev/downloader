// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "./ReentrancyGuard.sol";

import "./CegaStorage.sol";
import "./Structs.sol";
import "./DCSStructs.sol";
import "./IAddressManager.sol";
import "./IACLManager.sol";
import "./IDCSConfigurationEntry.sol";
import "./Errors.sol";

contract DCSConfigurationEntry is
    IDCSConfigurationEntry,
    CegaStorage,
    ReentrancyGuard
{
    // CONSTANTS

    uint256 private constant MAX_BPS = 1e4;

    IAddressManager private immutable addressManager;

    // EVENTS

    event DCSLateFeeBpsUpdated(uint32 indexed productId, uint16 lateFeeBps);

    event DCSMinDepositAmountUpdated(
        uint32 indexed productId,
        uint128 minDepositAmount
    );

    event DCSMinWithdrawalAmountUpdated(
        uint32 indexed productId,
        uint128 minWithdrawalAmount
    );

    event DCSIsDepositQueueOpenUpdated(
        uint32 indexed productId,
        bool isDepositQueueOpen
    );

    event DCSMaxUnderlyingAmountLimitUpdated(
        uint32 indexed productId,
        uint128 maxUnderlyingAmountLimit
    );

    event DCSManagementFeeUpdated(address indexed vaultAddress, uint16 value);

    event DCSYieldFeeUpdated(address indexed vaultAddress, uint16 value);

    event DCSDisputePeriodInHoursUpdated(
        uint32 indexed productId,
        uint8 disputePeriodInHours
    );

    event DCSDaysToStartLateFeesUpdated(
        uint32 indexed productId,
        uint8 daysToStartLateFees
    );

    event DCSDaysToStartAuctionDefaultUpdated(
        uint32 indexed productId,
        uint8 daysToStartAuctionDefault
    );

    event DCSDaysToStartSettlementDefaultUpdated(
        uint32 indexed productId,
        uint8 daysToStartSettlementDefault
    );

    event ProductNameUpdated(uint32 indexed productId, string name);

    event TradeWinnerNftImageUpdated(uint32 indexed productId, string imageUrl);

    // MODIFIERS

    modifier onlyCegaAdmin() {
        require(
            IACLManager(addressManager.getACLManager()).isCegaAdmin(msg.sender),
            Errors.NOT_CEGA_ADMIN
        );
        _;
    }

    modifier onlyTraderAdmin() {
        require(
            IACLManager(addressManager.getACLManager()).isTraderAdmin(
                msg.sender
            ),
            Errors.NOT_TRADER_ADMIN
        );
        _;
    }

    // CONSTRUCTOR

    constructor(IAddressManager _addressManager) {
        addressManager = _addressManager;
    }

    // FUNCTIONS

    /**
     * @notice Sets the late fee bps amount for this DCS product
     * @param lateFeeBps is the new lateFeeBps
     * @param productId id of the DCS product
     */
    function dcsSetLateFeeBps(
        uint16 lateFeeBps,
        uint32 productId
    ) external onlyTraderAdmin {
        require(lateFeeBps > 0, Errors.VALUE_IS_ZERO);
        DCSProduct storage dcsProduct = getStorage().dcsProducts[productId];
        dcsProduct.lateFeeBps = lateFeeBps;
        emit DCSLateFeeBpsUpdated(productId, lateFeeBps);
    }

    /**
     * @notice Sets the min deposit amount for the product
     * @param minDepositAmount is the minimum units of underlying for a user to deposit
     */
    function dcsSetMinDepositAmount(
        uint128 minDepositAmount,
        uint32 productId
    ) external onlyTraderAdmin {
        require(minDepositAmount != 0, Errors.VALUE_IS_ZERO);
        DCSProduct storage dcsProduct = getStorage().dcsProducts[productId];
        dcsProduct.minDepositAmount = minDepositAmount;
        emit DCSMinDepositAmountUpdated(productId, minDepositAmount);
    }

    /**
     * @notice Sets the min withdrawal amount for the product
     * @param minWithdrawalAmount is the minimum units of vault shares for a user to withdraw
     */
    function dcsSetMinWithdrawalAmount(
        uint128 minWithdrawalAmount,
        uint32 productId
    ) external onlyTraderAdmin {
        require(minWithdrawalAmount != 0, Errors.VALUE_IS_ZERO);
        DCSProduct storage dcsProduct = getStorage().dcsProducts[productId];
        dcsProduct.minWithdrawalAmount = minWithdrawalAmount;
        emit DCSMinWithdrawalAmountUpdated(productId, minWithdrawalAmount);
    }

    /**
     * @notice Toggles whether the product is open or closed for deposits
     * @param isDepositQueueOpen is a boolean for whether the deposit queue is accepting deposits
     */
    function dcsSetIsDepositQueueOpen(
        bool isDepositQueueOpen,
        uint32 productId
    ) external onlyTraderAdmin {
        CegaGlobalStorage storage cgs = getStorage();
        DCSProduct storage dcsProduct = cgs.dcsProducts[productId];
        dcsProduct.isDepositQueueOpen = isDepositQueueOpen;
        emit DCSIsDepositQueueOpenUpdated(productId, isDepositQueueOpen);
    }

    function dcsSetDaysToStartLateFees(
        uint32 productId,
        uint8 daysToStartLateFees
    ) external onlyTraderAdmin {
        require(daysToStartLateFees != 0, Errors.VALUE_IS_ZERO);

        DCSProduct storage dcsProduct = getStorage().dcsProducts[productId];
        dcsProduct.daysToStartLateFees = daysToStartLateFees;

        emit DCSDaysToStartLateFeesUpdated(productId, daysToStartLateFees);
    }

    function dcsSetDaysToStartAuctionDefault(
        uint32 productId,
        uint8 daysToStartAuctionDefault
    ) external onlyTraderAdmin {
        require(daysToStartAuctionDefault != 0, Errors.VALUE_IS_ZERO);

        DCSProduct storage dcsProduct = getStorage().dcsProducts[productId];
        dcsProduct.daysToStartAuctionDefault = daysToStartAuctionDefault;

        emit DCSDaysToStartAuctionDefaultUpdated(
            productId,
            daysToStartAuctionDefault
        );
    }

    function dcsSetDaysToStartSettlementDefault(
        uint32 productId,
        uint8 daysToStartSettlementDefault
    ) external onlyTraderAdmin {
        require(daysToStartSettlementDefault != 0, Errors.VALUE_IS_ZERO);

        DCSProduct storage dcsProduct = getStorage().dcsProducts[productId];
        dcsProduct.daysToStartSettlementDefault = daysToStartSettlementDefault;

        emit DCSDaysToStartSettlementDefaultUpdated(
            productId,
            daysToStartSettlementDefault
        );
    }

    /**
     * @notice Sets the maximum deposit limit for the product
     * @param maxUnderlyingAmountLimit is the deposit limit for the product
     */
    function dcsSetMaxUnderlyingAmount(
        uint128 maxUnderlyingAmountLimit,
        uint32 productId
    ) external onlyTraderAdmin {
        CegaGlobalStorage storage cgs = getStorage();
        DCSProduct storage dcsProduct = cgs.dcsProducts[productId];
        DepositQueue storage depositQueue = cgs.dcsDepositQueues[productId];
        require(
            depositQueue.queuedDepositsTotalAmount +
                dcsProduct.sumVaultUnderlyingAmounts <=
                maxUnderlyingAmountLimit,
            Errors.VALUE_TOO_SMALL
        );
        dcsProduct.maxUnderlyingAmountLimit = maxUnderlyingAmountLimit;
        emit DCSMaxUnderlyingAmountLimitUpdated(
            productId,
            maxUnderlyingAmountLimit
        );
    }

    function dcsSetManagementFee(
        address vaultAddress,
        uint16 value
    ) external onlyTraderAdmin {
        require(value <= MAX_BPS, Errors.VALUE_TOO_LARGE);

        CegaGlobalStorage storage cgs = getStorage();
        cgs.vaults[vaultAddress].managementFeeBps = value;

        emit DCSManagementFeeUpdated(vaultAddress, value);
    }

    function dcsSetYieldFee(
        address vaultAddress,
        uint16 value
    ) external onlyTraderAdmin {
        require(value <= MAX_BPS, Errors.VALUE_TOO_LARGE);

        CegaGlobalStorage storage cgs = getStorage();
        cgs.vaults[vaultAddress].yieldFeeBps = value;

        emit DCSYieldFeeUpdated(vaultAddress, value);
    }

    function dcsSetDisputePeriodInHours(
        uint32 productId,
        uint8 disputePeriodInHours
    ) external onlyTraderAdmin {
        require(disputePeriodInHours > 0, Errors.VALUE_TOO_SMALL);

        DCSProduct storage dcsProduct = getStorage().dcsProducts[productId];
        dcsProduct.disputePeriodInHours = disputePeriodInHours;

        emit DCSDisputePeriodInHoursUpdated(productId, disputePeriodInHours);
    }

    function setProductName(
        uint32 productId,
        string calldata name
    ) external onlyTraderAdmin {
        CegaGlobalStorage storage cgs = getStorage();
        cgs.productMetadata[productId].name = name;

        emit ProductNameUpdated(productId, name);
    }

    function setTradeWinnerNftImage(
        uint32 productId,
        string calldata imageUrl
    ) external onlyTraderAdmin {
        CegaGlobalStorage storage cgs = getStorage();
        cgs.productMetadata[productId].tradeWinnerNftImage = imageUrl;

        emit TradeWinnerNftImageUpdated(productId, imageUrl);
    }
}
