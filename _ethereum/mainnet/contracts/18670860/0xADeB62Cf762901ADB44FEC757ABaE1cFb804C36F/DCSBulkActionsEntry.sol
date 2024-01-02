// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.17;

import "./SafeCast.sol";
import "./ReentrancyGuard.sol";

import "./CegaStorage.sol";
import "./Structs.sol";
import "./DCSStructs.sol";
import "./DCSLogic.sol";
import "./VaultLogic.sol";
import "./IAddressManager.sol";
import "./ITradeWinnerNFT.sol";
import "./ITreasury.sol";
import "./IACLManager.sol";
import "./IOracleEntry.sol";
import "./IDCSBulkActionsEntry.sol";
import "./Errors.sol";

contract DCSBulkActionsEntry is
    IDCSBulkActionsEntry,
    CegaStorage,
    ReentrancyGuard
{
    using SafeCast for uint256;

    // IMMUTABLE

    IAddressManager private immutable addressManager;

    ITreasury private immutable treasury;

    // EVENTS

    event DepositProcessed(
        address indexed vaultAddress,
        address receiver,
        uint128 amount
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

    event DCSTradeStarted(
        address indexed vaultAddress,
        address auctionWinner,
        uint128 notionalAmount,
        uint128 yieldAmount
    );

    event DCSVaultRolledOver(address indexed vaultAddress);

    // MODIFIERS

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

    // FUNCTIONS

    function dcsBulkStartTrades(
        address[] calldata vaultAddresses
    ) external payable nonReentrant {
        CegaGlobalStorage storage cgs = getStorage();

        MMNFTMetadata[] memory nftMetadatas = new MMNFTMetadata[](
            vaultAddresses.length
        );
        uint256 totalNativeValueReceived;
        for (uint256 i = 0; i < vaultAddresses.length; i++) {
            uint256 nativeValueReceived;
            (nativeValueReceived, nftMetadatas[i]) = DCSLogic.startTrade(
                cgs,
                vaultAddresses[i],
                address(0),
                treasury,
                addressManager
            );
            totalNativeValueReceived += nativeValueReceived;
        }

        require(totalNativeValueReceived <= msg.value, Errors.VALUE_TOO_SMALL);

        uint256[] memory tokenIds = ITradeWinnerNFT(
            addressManager.getTradeWinnerNFT()
        ).mintBatch(msg.sender, nftMetadatas);
        for (uint256 i = 0; i < vaultAddresses.length; i++) {
            cgs.vaults[vaultAddresses[i]].auctionWinnerTokenId = tokenIds[i]
                .toUint64();
        }
    }

    function dcsBulkOpenVaultDeposits(
        address[] calldata vaultAddresses
    ) external nonReentrant onlyTraderAdmin {
        CegaGlobalStorage storage cgs = getStorage();
        for (uint256 i = 0; i < vaultAddresses.length; i++) {
            VaultLogic.openVaultDeposits(cgs, vaultAddresses[i]);
        }
    }

    function dcsBulkProcessDepositQueues(
        address[] calldata vaultAddresses,
        uint256 maxProcessCount
    ) external nonReentrant onlyTraderAdmin {
        CegaGlobalStorage storage cgs = getStorage();
        for (uint256 i = 0; i < vaultAddresses.length; i++) {
            maxProcessCount -= DCSLogic.processDepositQueue(
                cgs,
                vaultAddresses[i],
                maxProcessCount
            );
            if (maxProcessCount == 0) {
                return;
            }
        }
    }

    function dcsBulkProcessWithdrawalQueues(
        address[] calldata vaultAddresses,
        uint256 maxProcessCount
    ) external nonReentrant onlyTraderAdmin {
        CegaGlobalStorage storage cgs = getStorage();
        for (uint256 i = 0; i < vaultAddresses.length; i++) {
            maxProcessCount -= DCSLogic.processWithdrawalQueue(
                cgs,
                treasury,
                addressManager,
                vaultAddresses[i],
                maxProcessCount
            );
            if (maxProcessCount == 0) {
                return;
            }
        }
    }

    function dcsBulkRolloverVaults(
        address[] calldata vaultAddresses
    ) external nonReentrant onlyTraderAdmin {
        CegaGlobalStorage storage cgs = getStorage();
        for (uint256 i = 0; i < vaultAddresses.length; i++) {
            VaultLogic.rolloverVault(cgs, vaultAddresses[i]);
        }
    }

    function dcsBulkCheckTradesExpiry(
        address[] calldata vaultAddresses
    ) external nonReentrant {
        CegaGlobalStorage storage cgs = getStorage();
        for (uint256 i = 0; i < vaultAddresses.length; i++) {
            DCSLogic.checkTradeExpiry(cgs, addressManager, vaultAddresses[i]);
        }
    }

    function dcsBulkCheckAuctionDefault(
        address[] calldata vaultAddresses
    ) external nonReentrant {
        CegaGlobalStorage storage cgs = getStorage();
        for (uint256 i = 0; i < vaultAddresses.length; i++) {
            DCSLogic.checkAuctionDefault(cgs, vaultAddresses[i]);
        }
    }

    function dcsBulkCheckSettlementDefault(
        address[] calldata vaultAddresses
    ) external nonReentrant {
        CegaGlobalStorage storage cgs = getStorage();
        for (uint256 i = 0; i < vaultAddresses.length; i++) {
            DCSLogic.checkSettlementDefault(cgs, vaultAddresses[i]);
        }
    }

    function dcsBulkSettleVaults(
        address[] calldata vaultAddresses
    ) external payable nonReentrant {
        CegaGlobalStorage storage cgs = getStorage();

        uint256 totalNativeValueReceived;
        for (uint256 i = 0; i < vaultAddresses.length; i++) {
            totalNativeValueReceived += DCSLogic.settleVault(
                cgs,
                vaultAddresses[i],
                treasury,
                addressManager
            );
        }

        require(totalNativeValueReceived <= msg.value, Errors.VALUE_TOO_SMALL);
    }

    function dcsBulkCollectFees(
        address[] calldata vaultAddresses
    ) external onlyTraderAdmin nonReentrant {
        CegaGlobalStorage storage cgs = getStorage();
        for (uint256 i = 0; i < vaultAddresses.length; i++) {
            DCSLogic.collectVaultFees(
                cgs,
                treasury,
                addressManager,
                vaultAddresses[i]
            );
        }
    }
}
