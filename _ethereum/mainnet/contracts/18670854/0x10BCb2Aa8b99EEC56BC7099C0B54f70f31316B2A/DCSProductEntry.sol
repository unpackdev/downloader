// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.17;

import "./SafeERC20.sol";
import "./IERC20Metadata.sol";
import "./ReentrancyGuard.sol";
import "./Math.sol";

import "./CegaStorage.sol";
import "./Structs.sol";
import "./DCSStructs.sol";
import "./Transfers.sol";
import "./VaultLogic.sol";
import "./DCSLogic.sol";
import "./IDCSProductEntry.sol";
import "./ICegaVault.sol";
import "./ITreasury.sol";
import "./IAddressManager.sol";
import "./IACLManager.sol";
import "./IOracleEntry.sol";
import "./Errors.sol";

contract DCSProductEntry is IDCSProductEntry, CegaStorage, ReentrancyGuard {
    using Transfers for address;

    // CONSTANTS

    uint256 private constant MAX_BPS = 1e4;

    uint128 private constant BPS_DECIMALS = 1e4;

    IAddressManager private immutable addressManager;

    ITreasury private immutable treasury;

    // EVENTS

    event DCSProductCreated(uint32 indexed productId);

    event DepositQueued(
        uint32 indexed productId,
        address sender,
        address receiver,
        uint128 amount
    );

    event DepositProcessed(
        address indexed vaultAddress,
        address receiver,
        uint128 amount
    );

    event WithdrawalQueued(
        address indexed vaultAddress,
        uint256 sharesAmount,
        address owner,
        uint32 nextProductId
    );

    event WithdrawalProcessed(
        address indexed vaultAddress,
        uint256 sharesAmount,
        address owner,
        uint32 nextProductId
    );

    event VaultStatusUpdated(
        address indexed vaultAddress,
        VaultStatus vaultStatus
    );

    event DCSSettlementStatusUpdated(
        address indexed vaultAddress,
        SettlementStatus settlementStatus
    );

    event DCSVaultFeesCollected(
        address indexed vaultAddress,
        uint128 totalFees,
        uint128 managementFee,
        uint128 yieldFee
    );

    event DCSDisputeSubmitted(address indexed vaultAddress);

    event DCSDisputeProcessed(
        address indexed vaultAddress,
        bool isDisputeAccepted,
        uint40 timestamp,
        uint128 newPrice
    );

    // MODIFIERS

    modifier onlyValidVault(address vaultAddress) {
        CegaGlobalStorage storage cgs = getStorage();
        require(cgs.vaults[vaultAddress].productId != 0, Errors.INVALID_VAULT);
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

    modifier onlyCegaAdmin() {
        require(
            IACLManager(addressManager.getACLManager()).isCegaAdmin(msg.sender),
            Errors.NOT_CEGA_ADMIN
        );
        _;
    }

    // CONSTRUCTOR

    constructor(IAddressManager _addressManager, ITreasury _treasury) {
        addressManager = _addressManager;
        treasury = _treasury;
    }

    // VIEW FUNCTIONS

    // DCS-specific

    function dcsGetProduct(
        uint32 productId
    ) external view returns (DCSProduct memory) {
        CegaGlobalStorage storage cgs = getStorage();
        return cgs.dcsProducts[productId];
    }

    function dcsGetProductDepositAsset(
        uint32 productId
    ) external view returns (address) {
        return
            DCSLogic.dcsGetProductDepositAsset(
                getStorage().dcsProducts[productId]
            );
    }

    function dcsGetDepositQueue(
        uint32 productId
    )
        external
        view
        returns (
            address[] memory depositors,
            uint128[] memory amounts,
            uint128 totalAmount
        )
    {
        DepositQueue storage queue = getStorage().dcsDepositQueues[productId];
        uint256 index = queue.processedIndex;
        uint256 depositorsLength = queue.depositors.length - index;

        amounts = new uint128[](depositorsLength);
        depositors = new address[](depositorsLength);

        for (uint256 i = 0; i < depositorsLength; i++) {
            depositors[i] = queue.depositors[index + i];
            amounts[i] = queue.amounts[depositors[i]];
        }
        totalAmount = queue.queuedDepositsTotalAmount;
    }

    function dcsGetWithdrawalQueue(
        address vaultAddress
    )
        external
        view
        returns (
            Withdrawer[] memory withdrawers,
            uint256[] memory amounts,
            bool[] memory withProxy,
            uint256 totalAmount
        )
    {
        WithdrawalQueue storage queue = getStorage().dcsWithdrawalQueues[
            vaultAddress
        ];

        uint256 index = queue.processedIndex;
        uint256 withdrawersLength = queue.withdrawers.length - index;

        withdrawers = new Withdrawer[](withdrawersLength);
        amounts = new uint256[](withdrawersLength);
        withProxy = new bool[](withdrawersLength);

        for (uint256 i = 0; i < withdrawersLength; i++) {
            Withdrawer memory withdrawer = queue.withdrawers[index + i];
            withdrawers[i] = withdrawer;
            address account = withdrawer.account;
            uint32 nextProductId = withdrawer.nextProductId;
            amounts[i] = queue.amounts[account][nextProductId];
            if (nextProductId == 0) {
                withProxy[i] = queue.withdrawingWithProxy[account];
            }
        }
        totalAmount = queue.queuedWithdrawalSharesAmount;
    }

    function dcsIsWithdrawalPossible(
        address vaultAddress
    ) external view returns (bool) {
        CegaGlobalStorage storage cgs = getStorage();
        return VaultLogic.isWithdrawalPossible(cgs, vaultAddress);
    }

    function dcsCalculateVaultFinalPayoff(
        address vaultAddress
    ) external view returns (uint128) {
        CegaGlobalStorage storage cgs = getStorage();
        return
            DCSLogic.calculateVaultFinalPayoff(
                cgs,
                addressManager,
                vaultAddress
            );
    }

    // MUTATIVE FUNCTIONS

    // DCS-Specific

    function dcsCreateProduct(
        DCSProductCreationParams calldata creationParams
    ) external onlyTraderAdmin returns (uint32) {
        CegaGlobalStorage storage cgs = getStorage();
        require(
            creationParams.quoteAssetAddress != creationParams.baseAssetAddress,
            Errors.INVALID_QUOTE_OR_BASE_ASSETS
        );
        require(
            creationParams.minDepositAmount > 0,
            Errors.INVALID_MIN_DEPOSIT_AMOUNT
        );
        require(
            creationParams.minDepositAmount <=
                creationParams.maxUnderlyingAmountLimit,
            Errors.INVALID_MIN_DEPOSIT_AMOUNT
        );
        require(
            creationParams.minWithdrawalAmount > 0,
            Errors.INVALID_MIN_WITHDRAWAL_AMOUNT
        );

        if (creationParams.dcsOptionType == DCSOptionType.BuyLow) {
            require(
                creationParams.strikeBarrierBps <= MAX_BPS,
                Errors.INVALID_STRIKE_PRICE
            );
        } else {
            require(
                creationParams.strikeBarrierBps >= MAX_BPS,
                Errors.INVALID_STRIKE_PRICE
            );
        }
        require(creationParams.tenorInSeconds != 0, Errors.VALUE_IS_ZERO);
        require(creationParams.daysToStartLateFees != 0, Errors.VALUE_IS_ZERO);
        require(
            creationParams.daysToStartAuctionDefault != 0,
            Errors.VALUE_IS_ZERO
        );
        require(
            creationParams.daysToStartSettlementDefault != 0,
            Errors.VALUE_IS_ZERO
        );
        require(creationParams.disputePeriodInHours != 0, Errors.VALUE_IS_ZERO);

        address[] memory vaultAddresses;
        uint32 newId = ++cgs.productIdCounter;

        cgs.dcsProducts[newId] = DCSProduct({
            dcsOptionType: creationParams.dcsOptionType,
            isDepositQueueOpen: false,
            quoteAssetAddress: creationParams.quoteAssetAddress,
            baseAssetAddress: creationParams.baseAssetAddress,
            maxUnderlyingAmountLimit: creationParams.maxUnderlyingAmountLimit,
            minDepositAmount: creationParams.minDepositAmount,
            minWithdrawalAmount: creationParams.minWithdrawalAmount,
            sumVaultUnderlyingAmounts: 0,
            vaults: vaultAddresses,
            daysToStartLateFees: creationParams.daysToStartLateFees,
            daysToStartAuctionDefault: creationParams.daysToStartAuctionDefault,
            daysToStartSettlementDefault: creationParams
                .daysToStartSettlementDefault,
            lateFeeBps: creationParams.lateFeeBps,
            strikeBarrierBps: creationParams.strikeBarrierBps,
            tenorInSeconds: creationParams.tenorInSeconds,
            disputePeriodInHours: creationParams.disputePeriodInHours
        });
        cgs.strategyOfProduct[newId] = DCS_STRATEGY_ID;

        cgs.productMetadata[newId].tradeWinnerNftImage = creationParams
            .tradeWinnerNftImage;
        cgs.productMetadata[newId].name = creationParams.name;
        emit DCSProductCreated(newId);

        return newId;
    }

    function dcsAddToDepositQueue(
        uint32 productId,
        uint128 amount,
        address receiver
    ) external payable {
        CegaGlobalStorage storage cgs = getStorage();
        DCSProduct storage dcsProduct = cgs.dcsProducts[productId];
        require(dcsProduct.isDepositQueueOpen, Errors.DEPOSIT_QUEUE_NOT_OPEN);
        require(amount >= dcsProduct.minDepositAmount, Errors.VALUE_TOO_SMALL);

        DepositQueue storage depositQueue = cgs.dcsDepositQueues[productId];

        uint128 _queuedDepositsTotalAmount = depositQueue
            .queuedDepositsTotalAmount + amount;
        depositQueue.queuedDepositsTotalAmount = _queuedDepositsTotalAmount;
        require(
            dcsProduct.sumVaultUnderlyingAmounts + _queuedDepositsTotalAmount <=
                dcsProduct.maxUnderlyingAmountLimit,
            Errors.MAX_DEPOSIT_LIMIT_REACHED
        );

        uint128 currentQueuedAmount = depositQueue.amounts[receiver];
        if (currentQueuedAmount == 0) {
            depositQueue.depositors.push(receiver);
        }
        depositQueue.amounts[receiver] = currentQueuedAmount + amount;

        address depositAsset = DCSLogic.dcsGetProductDepositAsset(dcsProduct);
        depositAsset.receiveTo(address(treasury), amount);

        emit DepositQueued(productId, msg.sender, receiver, amount);
    }

    function dcsProcessDepositQueue(
        address vaultAddress,
        uint256 maxProcessCount
    ) external onlyTraderAdmin nonReentrant {
        CegaGlobalStorage storage cgs = getStorage();
        DCSLogic.processDepositQueue(cgs, vaultAddress, maxProcessCount);
    }

    function dcsAddToWithdrawalQueue(
        address vaultAddress,
        uint128 sharesAmount,
        uint32 nextProductId
    ) external nonReentrant onlyValidVault(vaultAddress) {
        CegaGlobalStorage storage cgs = getStorage();
        DCSLogic.addToWithdrawalQueue(
            cgs,
            vaultAddress,
            sharesAmount,
            nextProductId,
            false
        );
    }

    function dcsAddToWithdrawalQueueWithProxy(
        address vaultAddress,
        uint128 sharesAmount
    ) external nonReentrant onlyValidVault(vaultAddress) {
        CegaGlobalStorage storage cgs = getStorage();
        DCSLogic.addToWithdrawalQueue(cgs, vaultAddress, sharesAmount, 0, true);
    }

    function dcsProcessWithdrawalQueue(
        address vaultAddress,
        uint256 maxProcessCount
    ) external onlyTraderAdmin nonReentrant {
        CegaGlobalStorage storage cgs = getStorage();
        DCSLogic.processWithdrawalQueue(
            cgs,
            treasury,
            addressManager,
            vaultAddress,
            maxProcessCount
        );
    }

    function dcsCheckTradeExpiry(address vaultAddress) external nonReentrant {
        CegaGlobalStorage storage cgs = getStorage();
        DCSLogic.checkTradeExpiry(cgs, addressManager, vaultAddress);
    }

    function dcsCheckSettlementDefault(
        address vaultAddress
    ) external nonReentrant {
        CegaGlobalStorage storage cgs = getStorage();
        DCSLogic.checkSettlementDefault(cgs, vaultAddress);
    }

    function dcsCollectVaultFees(
        address vaultAddress
    ) external onlyTraderAdmin nonReentrant {
        CegaGlobalStorage storage cgs = getStorage();

        DCSLogic.collectVaultFees(cgs, treasury, addressManager, vaultAddress);
    }

    function dcsSubmitDispute(
        address vaultAddress
    ) external onlyValidVault(vaultAddress) {
        CegaGlobalStorage storage cgs = getStorage();

        VaultLogic.disputeVault(
            cgs,
            vaultAddress,
            addressManager.getTradeWinnerNFT(),
            IACLManager(addressManager.getACLManager())
        );
    }

    function dcsProcessTradeDispute(
        address vaultAddress,
        uint128 newPrice
    ) external onlyCegaAdmin onlyValidVault(vaultAddress) {
        CegaGlobalStorage storage cgs = getStorage();

        VaultLogic.processDispute(cgs, vaultAddress, newPrice);
    }
}
