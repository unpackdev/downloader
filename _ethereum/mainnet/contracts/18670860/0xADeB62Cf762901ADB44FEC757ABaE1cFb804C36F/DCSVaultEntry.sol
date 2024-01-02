// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.17;

import "./ERC20.sol";
import "./ReentrancyGuard.sol";

import "./IDCSVaultEntry.sol";

import "./CegaVault.sol";
import "./IOracleEntry.sol";
import "./CegaStorage.sol";
import "./Structs.sol";
import "./DCSStructs.sol";
import "./IAddressManager.sol";
import "./ITradeWinnerNFT.sol";
import "./IACLManager.sol";
import "./IOracleEntry.sol";
import "./ITreasury.sol";

import "./VaultLogic.sol";
import "./DCSLogic.sol";

import "./Transfers.sol";
import "./Errors.sol";

contract DCSVaultEntry is IDCSVaultEntry, CegaStorage, ReentrancyGuard {
    using Transfers for address;

    uint128 private constant BPS_DECIMALS = 1e4;

    // CONSTANTS

    IAddressManager private immutable addressManager;

    ITreasury private immutable treasury;

    // EVENTS

    event VaultCreated(
        uint32 indexed productId,
        address indexed vaultAddress,
        string _tokenSymbol,
        string _tokenName
    );

    event DCSAuctionEnded(
        address indexed vaultAddress,
        address indexed auctionWinner,
        uint40 tradeStartDate,
        uint16 aprBps,
        uint128 initialSpotPrice,
        uint128 strikePrice
    );

    event VaultStatusUpdated(
        address indexed vaultAddress,
        VaultStatus vaultStatus
    );

    event DCSSettlementStatusUpdated(
        address indexed vaultAddress,
        SettlementStatus settlementStatus
    );

    event DCSIsPayoffInDepositAssetUpdated(
        address indexed vaultAddress,
        bool isPayoffInDepositAsset
    );

    event DCSTradeStarted(
        address indexed vaultAddress,
        address auctionWinner,
        uint128 notionalAmount,
        uint128 yieldAmount
    );

    event DCSVaultSettled(
        address indexed vaultAddress,
        address settler,
        uint128 depositedAmount,
        uint128 withdrawnAmount
    );

    event DCSVaultRolledOver(address vaultAddress);

    // MODIFIERS

    modifier onlyValidVault(address vaultAddress) {
        CegaGlobalStorage storage cgs = getStorage();
        require(cgs.vaults[vaultAddress].productId != 0, Errors.INVALID_VAULT);
        _;
    }

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

    constructor(IAddressManager _addressManager, ITreasury _treasury) {
        addressManager = _addressManager;
        treasury = _treasury;
    }

    // VIEW FUNCTIONS

    // DCS-specific

    function dcsGetVault(
        address vaultAddress
    ) external view onlyValidVault(vaultAddress) returns (DCSVault memory) {
        CegaGlobalStorage storage cgs = getStorage();
        return cgs.dcsVaults[vaultAddress];
    }

    function dcsCalculateLateFee(
        address vaultAddress
    ) external view onlyValidVault(vaultAddress) returns (uint128) {
        CegaGlobalStorage storage cgs = getStorage();
        Vault storage vault = cgs.vaults[vaultAddress];
        DCSVault storage dcsVault = cgs.dcsVaults[vaultAddress];
        DCSProduct storage dcsProduct = cgs.dcsProducts[vault.productId];
        return
            VaultLogic.calculateLateFee(
                dcsVault.totalYield,
                vault.tradeStartDate,
                dcsProduct.lateFeeBps,
                dcsProduct.daysToStartLateFees,
                dcsProduct.daysToStartAuctionDefault
            );
    }

    function dcsGetCouponPayment(
        address vaultAddress
    ) external view onlyValidVault(vaultAddress) returns (uint128) {
        CegaGlobalStorage storage cgs = getStorage();
        Vault storage vault = cgs.vaults[vaultAddress];
        DCSProduct storage dcsProduct = cgs.dcsProducts[vault.productId];

        uint40 endDate = vault.tradeStartDate + dcsProduct.tenorInSeconds;

        return VaultLogic.getCurrentYield(cgs, vaultAddress, endDate);
    }

    function dcsGetVaultSettlementAsset(
        address vaultAddress
    ) external view onlyValidVault(vaultAddress) returns (address) {
        CegaGlobalStorage storage cgs = getStorage();
        return DCSLogic.getVaultSettlementAsset(cgs, vaultAddress);
    }

    // MUTATIVE FUNCTIONS

    // Generic

    function overrideOraclePrice(
        address vaultAddress,
        uint40 timestamp,
        uint128 newPrice
    ) external onlyCegaAdmin onlyValidVault(vaultAddress) {
        CegaGlobalStorage storage cgs = getStorage();
        require(newPrice != 0, Errors.VALUE_IS_ZERO);
        require(timestamp != 0, Errors.VALUE_IS_ZERO);

        VaultLogic.overrideOraclePrice(cgs, vaultAddress, timestamp, newPrice);
    }

    function openVaultDeposits(address vaultAddress) external onlyTraderAdmin {
        CegaGlobalStorage storage cgs = getStorage();
        VaultLogic.openVaultDeposits(cgs, vaultAddress);
    }

    function setVaultStatus(
        address vaultAddress,
        VaultStatus _vaultStatus
    ) external onlyCegaAdmin {
        CegaGlobalStorage storage cgs = getStorage();
        VaultLogic.setVaultStatus(cgs, vaultAddress, _vaultStatus);
    }

    // DCS-specific

    function dcsCreateVault(
        uint32 _productId,
        string memory _tokenName,
        string memory _tokenSymbol
    ) external onlyTraderAdmin returns (address vaultAddress) {
        CegaGlobalStorage storage cgs = getStorage();
        require(_productId <= cgs.productIdCounter, Errors.VALUE_TOO_LARGE);
        DCSProduct storage product = cgs.dcsProducts[_productId];

        CegaVault vaultContract = new CegaVault(
            addressManager,
            _tokenName,
            _tokenSymbol
        );
        address newVaultAddress = address(vaultContract);
        product.vaults.push(newVaultAddress);

        Vault storage vault = cgs.vaults[newVaultAddress];
        vault.productId = _productId;

        cgs.dcsVaults[newVaultAddress].isPayoffInDepositAsset = true;
        emit DCSIsPayoffInDepositAssetUpdated(newVaultAddress, true);

        emit VaultCreated(
            _productId,
            newVaultAddress,
            _tokenSymbol,
            _tokenName
        );

        return newVaultAddress;
    }

    /**
     * Once the winner of an auction is determined, this function sets the vault state so it is ready
     * to start the trade.
     *
     * @param vaultAddress address of the vault
     * @param _auctionWinner address of the winner
     * @param _tradeStartDate when the trade starts
     * @param _aprBps the apr of the vault
     */
    function dcsEndAuction(
        address vaultAddress,
        address _auctionWinner,
        uint40 _tradeStartDate,
        uint16 _aprBps,
        IOracleEntry.DataSource _dataSource
    ) external nonReentrant onlyValidVault(vaultAddress) onlyTraderAdmin {
        CegaGlobalStorage storage cgs = getStorage();
        Vault storage vault = cgs.vaults[vaultAddress];
        DCSVault storage dcsVault = cgs.dcsVaults[vaultAddress];
        DCSProduct storage dcsProduct = cgs.dcsProducts[vault.productId];
        require(
            vault.vaultStatus == VaultStatus.NotTraded,
            Errors.INVALID_VAULT_STATUS
        );
        SettlementStatus settlementStatus = dcsVault.settlementStatus;

        require(
            settlementStatus == SettlementStatus.NotAuctioned ||
                settlementStatus == SettlementStatus.Auctioned,
            Errors.INVALID_SETTLEMENT_STATUS
        );

        require(_tradeStartDate != 0, Errors.VALUE_IS_ZERO);

        vault.auctionWinner = _auctionWinner;
        vault.tradeStartDate = _tradeStartDate;
        vault.dataSource = _dataSource;

        dcsVault.aprBps = _aprBps;
        uint128 initialSpotPrice = DCSLogic.getSpotPriceAt(
            cgs,
            vaultAddress,
            addressManager,
            vault.tradeStartDate
        );
        dcsVault.initialSpotPrice = initialSpotPrice;

        uint128 strikePrice = (dcsVault.initialSpotPrice *
            dcsProduct.strikeBarrierBps) / BPS_DECIMALS;
        dcsVault.strikePrice = strikePrice;

        VaultLogic.setVaultSettlementStatus(
            cgs,
            vaultAddress,
            SettlementStatus.Auctioned
        );

        emit DCSAuctionEnded(
            vaultAddress,
            _auctionWinner,
            _tradeStartDate,
            _aprBps,
            initialSpotPrice,
            strikePrice
        );
    }

    /**
     *
     * @param vaultAddress address of the vault to start trading
     */
    function dcsStartTrade(address vaultAddress) external payable nonReentrant {
        CegaGlobalStorage storage cgs = getStorage();
        (uint256 nativeValueReceived, ) = DCSLogic.startTrade(
            cgs,
            vaultAddress,
            addressManager.getTradeWinnerNFT(),
            treasury,
            addressManager
        );
        require(msg.value >= nativeValueReceived, Errors.VALUE_TOO_SMALL);
    }

    function dcsSettleVault(
        address vaultAddress
    ) external payable nonReentrant {
        CegaGlobalStorage storage cgs = getStorage();
        DCSLogic.settleVault(cgs, vaultAddress, treasury, addressManager);
    }

    function dcsCheckAuctionDefault(
        address vaultAddress
    ) external nonReentrant {
        CegaGlobalStorage storage cgs = getStorage();
        DCSLogic.checkAuctionDefault(cgs, vaultAddress);
    }

    function dcsRolloverVault(
        address vaultAddress
    ) external nonReentrant onlyTraderAdmin {
        CegaGlobalStorage storage cgs = getStorage();
        VaultLogic.rolloverVault(cgs, vaultAddress);
    }

    function dcsSetSettlementStatus(
        address vaultAddress,
        SettlementStatus _settlementStatus
    ) external onlyValidVault(vaultAddress) onlyCegaAdmin {
        CegaGlobalStorage storage cgs = getStorage();
        VaultLogic.setVaultSettlementStatus(
            cgs,
            vaultAddress,
            _settlementStatus
        );
    }

    function dcsSetIsPayoffInDepositAsset(
        address vaultAddress,
        bool newState
    ) external onlyValidVault(vaultAddress) onlyCegaAdmin {
        CegaGlobalStorage storage cgs = getStorage();
        cgs.dcsVaults[vaultAddress].isPayoffInDepositAsset = newState;

        emit DCSIsPayoffInDepositAssetUpdated(vaultAddress, newState);
    }
}
