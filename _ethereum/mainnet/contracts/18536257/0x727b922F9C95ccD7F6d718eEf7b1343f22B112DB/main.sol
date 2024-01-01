// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

import "./helpers.sol";
import "./IERC20Upgradeable.sol";

contract InstaETHVaultV2Resolver is Helpers {
    struct VaultInfo {
        address asset;
        uint8 decimals;
        address vaultAddr; // Lite v2 vault address.
        address vaultDsa; // Dsa address of Lite v2
        uint256 revenue; // Lite revenue
        uint256 revenueFeePercentage; // Current performance fee set in lite v2
        uint256 withdrawalFeePercentage; // Current performance fee set in lite v2
        uint256 withdrawFeeAbsoluteMin;
        uint256 exchangePrice; // iTokenV2 current exchange price
        uint256 revenueExchangePrice;
        uint256 vaultTVLInSteth;
        uint256 itotalSupply; // iTokenV2 total supply
        uint256 totalAssets; // Includes steth collateral + ideal balances - revenue.
        uint256 totalCollateral; // Includes collateral of all protocols in `STETH`.
        uint256 totalDebt; // Total weth debt across all protocols.
        uint256 netAssets; // Vault's net assets (ideal + collateral - debt) in terms of `STETH`.
        uint256 aggrRatio; // Aggregated vault ratio from all protocols.
        uint256 aggrMaxVaultRatio; // Max aggregated vault ratio set in the vault.
        uint256 leverageMaxUnitAmountLimit;
        uint256[] maxRiskRatios;
        VaultV2Interface.IdealBalances vaultBal; // vault's steth, wsteth, and weth balances.
        VaultV2Interface.IdealBalances dsaBal; // dsa's steth, wsteth, and weth balances.
        uint256 wstethInUsd;
        uint256 stethInUsd;
        uint256 ethInUsd;
    }

    /// @notice Returns all the necessary information of the vault.
    function getVaultInfo() public view returns (VaultInfo memory vaultInfo_) {
        VaultV2Interface.NetAssetsHelper memory assets_;

        vaultInfo_.asset = VAULT_V2.asset();
        vaultInfo_.decimals = VAULT_V2.decimals();
        vaultInfo_.vaultAddr = address(VAULT_V2);
        vaultInfo_.vaultDsa = VAULT_V2.vaultDSA();
        vaultInfo_.revenue = VAULT_V2.revenue();
        vaultInfo_.revenueFeePercentage = VAULT_V2.revenueFeePercentage();
        vaultInfo_.withdrawalFeePercentage = VAULT_V2.withdrawalFeePercentage();
        vaultInfo_.withdrawFeeAbsoluteMin = VAULT_V2.withdrawFeeAbsoluteMin();
        vaultInfo_.exchangePrice = VAULT_V2.exchangePrice();
        vaultInfo_.revenueExchangePrice = VAULT_V2.revenueExchangePrice();
        vaultInfo_.vaultTVLInSteth =
            (VAULT_V2.totalSupply() * VAULT_V2.exchangePrice()) /
            1e18;
        vaultInfo_.itotalSupply = VAULT_V2.totalSupply();
        (
            vaultInfo_.totalAssets,
            vaultInfo_.totalDebt,
            vaultInfo_.netAssets,
            vaultInfo_.aggrRatio,
            assets_
        ) = VAULT_V2.getNetAssets();
        vaultInfo_.totalAssets = vaultInfo_.totalAssets - VAULT_V2.revenue();

        vaultInfo_.aggrMaxVaultRatio = VAULT_V2.aggrMaxVaultRatio();
        // All the logics related to leverage to cover ratio difference will be added on the backend.

        vaultInfo_.leverageMaxUnitAmountLimit = VAULT_V2
            .leverageMaxUnitAmountLimit();

        vaultInfo_.vaultBal = assets_.vaultBalances;
        vaultInfo_.dsaBal = assets_.dsaBalances;

        uint256 wstethIdealBal = vaultInfo_.vaultBal.wstETH +
            vaultInfo_.dsaBal.wstETH;
        uint256 convertedSteth = WSTETH_CONTRACT.getStETHByWstETH(
            wstethIdealBal
        );

        vaultInfo_.totalCollateral =
            vaultInfo_.totalAssets -
            vaultInfo_.vaultBal.stETH -
            vaultInfo_.dsaBal.stETH -
            vaultInfo_.vaultBal.wETH -
            vaultInfo_.dsaBal.wETH -
            convertedSteth;

        vaultInfo_.maxRiskRatios = new uint256[](PROTOCOL_LENGTH);

        for (uint8 i = 0; i < PROTOCOL_LENGTH; i++) {
            vaultInfo_.maxRiskRatios[i] = VAULT_V2.maxRiskRatio(i + 1);
        }

        (
            vaultInfo_.wstethInUsd,
            vaultInfo_.stethInUsd,
            vaultInfo_.ethInUsd
        ) = getPricesInUsd();
    }

    struct InterestRatesInSteth {
        uint256 stETHSupplyRate;
        uint256 wETHBorrowRate;
    }

    struct InterestRatesInWsteth {
        uint256 wstETHSupplyRate;
        uint256 stETHSupplyRate;
        uint256 wETHBorrowRate;
    }

    struct InterestRatesMorpho {
        uint256 stETHSupplyRate;
        uint256 wETHBorrowRate;
        uint256 stETHPoolSupplyRate;
        uint256 stETHP2PSupplyRate;
        uint256 wETHPoolBorrowRate;
        uint256 wETHP2PBorrowRate;
    }

    struct InterestRatesMorphoV3Wsteth {
        uint256 wstETHSupplyRate; // Pool (there in no P2P for collateral tokens)
        uint256 stETHSupplyRate; // wstETH rate converted to stETH
        uint256 wETHBorrowRate;
        uint256 wETHPoolBorrowRate;
        uint256 wETHP2PBorrowRate;
    }

    struct ProtocolAssetsStETH {
        uint8 protocolId;
        uint256 stETHCol; // supply
        uint256 wETHDebt; // borrow
        uint256 ratio; // In terms of `WETH` and `STETH`
        uint256 maxRiskRatio; // In terms of `WETH` and `STETH`
        InterestRatesInSteth rates;
    }

    struct MorphoAssetsStETH {
        uint8 protocolId;
        uint256 stETHCol; // supply
        uint256 stETHColPool;
        uint256 stETHColP2P;
        uint256 wETHDebt; // borrow
        uint256 wETHDebtPool;
        uint256 wETHDebtP2P;
        uint256 ratio; // In terms of `WETH` and `STETH`
        uint256 maxRiskRatio; // In terms of `WETH` and `STETH`
        InterestRatesMorpho rates;
    }

    struct MorphoV3AssetsWstETH {
        uint8 protocolId;
        uint256 wstETHCol; // supply
        uint256 stETHCol; // supply
        uint256 wETHDebt; // borrow
        uint256 wETHDebtPool;
        uint256 wETHDebtP2P;
        uint256 ratio; // In terms of `WETH` and `STETH`
        uint256 maxRiskRatio; // In terms of `WETH` and `STETH`
        InterestRatesMorphoV3Wsteth rates;
    }

    struct ProtocolAssetsWstETH {
        uint8 protocolId;
        uint256 wstETHCol; // supply
        uint256 stETHCol; // supply
        uint256 wETHDebt; // borrow
        uint256 ratio; // In terms of `WETH` and `STETH`
        uint256 maxRiskRatio; // In terms of `WETH` and `STETH`
        InterestRatesInWsteth rates;
    }

    struct ProtocolInfo {
        ProtocolAssetsStETH aaveV2;
        ProtocolAssetsWstETH aaveV3;
        ProtocolAssetsWstETH compoundV3;
        ProtocolAssetsWstETH euler;
        MorphoAssetsStETH morphoAaveV2;
        MorphoV3AssetsWstETH morphoAaveV3;
        ProtocolAssetsWstETH spark;
    }

    /// @notice Returns all the necessary information of a protocol.
    function getAllProtocolInfo()
        public
        view
        returns (
            ProtocolInfo memory protoInfo_,
            uint256 stEthPerWsteth_,
            uint256 wstEthPerSteth_
        )
    {
        stEthPerWsteth_ = WSTETH_CONTRACT.stEthPerToken();
        wstEthPerSteth_ = WSTETH_CONTRACT.tokensPerStEth();

        /***********************************|
        |             PROTOCOL 1            |
        |__________________________________*/

        protoInfo_.aaveV2.protocolId = 1;

        (
            protoInfo_.aaveV2.stETHCol,
            protoInfo_.aaveV2.wETHDebt,
            protoInfo_.aaveV2.ratio
        ) = VAULT_V2.getRatioAaveV2();

        protoInfo_.aaveV2.maxRiskRatio = VAULT_V2.maxRiskRatio(1);

        (
            protoInfo_.aaveV2.rates.stETHSupplyRate,
            protoInfo_.aaveV2.rates.wETHBorrowRate
        ) = getAaveV2Rates();

        /***********************************|
        |             PROTOCOL 2            |
        |__________________________________*/

        protoInfo_.aaveV3.protocolId = 2;

        (
            protoInfo_.aaveV3.wstETHCol,
            protoInfo_.aaveV3.stETHCol,
            protoInfo_.aaveV3.wETHDebt,
            protoInfo_.aaveV3.ratio // (WETH / STETH)
        ) = VAULT_V2.getRatioAaveV3(stEthPerWsteth_);

        protoInfo_.aaveV3.maxRiskRatio = VAULT_V2.maxRiskRatio(2);

        (
            protoInfo_.aaveV3.rates.wstETHSupplyRate,
            protoInfo_.aaveV3.rates.wETHBorrowRate
        ) = getAaveV3Rates();

        protoInfo_.aaveV3.rates.stETHSupplyRate = convertWstethRateForSteth(
            protoInfo_.aaveV3.rates.wstETHSupplyRate,
            stEthPerWsteth_
        );

        /***********************************|
        |             PROTOCOL 3            |
        |__________________________________*/

        protoInfo_.compoundV3.protocolId = 3;

        (
            protoInfo_.compoundV3.wstETHCol,
            protoInfo_.compoundV3.stETHCol,
            protoInfo_.compoundV3.wETHDebt,
            protoInfo_.compoundV3.ratio // (WETH / STETH)
        ) = VAULT_V2.getRatioCompoundV3(stEthPerWsteth_);

        protoInfo_.compoundV3.maxRiskRatio = VAULT_V2.maxRiskRatio(3);

        (
            protoInfo_.compoundV3.rates.wstETHSupplyRate,
            protoInfo_.compoundV3.rates.wETHBorrowRate
        ) = getCompoundV3Rates();

        protoInfo_.compoundV3.rates.stETHSupplyRate = convertWstethRateForSteth(
            protoInfo_.compoundV3.rates.wstETHSupplyRate,
            stEthPerWsteth_
        );

        /***********************************|
        |             PROTOCOL 4            |
        |__________________________________*/

        protoInfo_.euler.protocolId = 4;
        protoInfo_.euler.maxRiskRatio = VAULT_V2.maxRiskRatio(4);

        /***********************************|
        |             PROTOCOL 5            |
        |__________________________________*/

        protoInfo_.morphoAaveV2.protocolId = 5;

        (
            protoInfo_.morphoAaveV2.stETHCol,
            protoInfo_.morphoAaveV2.stETHColPool,
            protoInfo_.morphoAaveV2.stETHColP2P,
            protoInfo_.morphoAaveV2.wETHDebt,
            protoInfo_.morphoAaveV2.wETHDebtPool,
            protoInfo_.morphoAaveV2.wETHDebtP2P,
            protoInfo_.morphoAaveV2.ratio
        ) = VAULT_V2.getRatioMorphoAaveV2();

        protoInfo_.morphoAaveV2.maxRiskRatio = VAULT_V2.maxRiskRatio(5);

        (
            protoInfo_.morphoAaveV2.rates.stETHPoolSupplyRate,
            protoInfo_.morphoAaveV2.rates.stETHP2PSupplyRate,
            protoInfo_.morphoAaveV2.rates.wETHPoolBorrowRate,
            protoInfo_.morphoAaveV2.rates.wETHP2PBorrowRate
        ) = getMorphoAaveV2Rates();

        protoInfo_.morphoAaveV2.rates.stETHSupplyRate = protoInfo_ // (1e18 * 1e27) / 1e18
            .morphoAaveV2
            .stETHCol == 0
            ? 0
            : (protoInfo_.morphoAaveV2.stETHColPool *
                protoInfo_.morphoAaveV2.rates.stETHPoolSupplyRate +
                protoInfo_.morphoAaveV2.stETHColP2P *
                protoInfo_.morphoAaveV2.rates.stETHP2PSupplyRate) /
                protoInfo_.morphoAaveV2.stETHCol;

        protoInfo_.morphoAaveV2.rates.wETHBorrowRate = protoInfo_ // (1e18 * 1e27) / 1e18
            .morphoAaveV2
            .wETHDebt == 0
            ? 0
            : (protoInfo_.morphoAaveV2.wETHDebtPool *
                protoInfo_.morphoAaveV2.rates.wETHPoolBorrowRate +
                protoInfo_.morphoAaveV2.wETHDebtP2P *
                protoInfo_.morphoAaveV2.rates.wETHP2PBorrowRate) /
                protoInfo_.morphoAaveV2.wETHDebt;

        /***********************************|
        |             PROTOCOL 6            |
        |__________________________________*/

        protoInfo_.morphoAaveV3.protocolId = 6;

        (
            protoInfo_.morphoAaveV3.wstETHCol,
            protoInfo_.morphoAaveV3.stETHCol,
            protoInfo_.morphoAaveV3.wETHDebt,
            protoInfo_.morphoAaveV3.ratio
        ) = VAULT_V2.getRatioMorphoAaveV3(stEthPerWsteth_);

        // Getting P2P and Pool amounts in underlying
        (
            protoInfo_.morphoAaveV3.wETHDebtP2P,
            protoInfo_.morphoAaveV3.wETHDebtPool,

        ) = borrowBalanceUser(WETH_ADDRESS, address(VAULT_DSA));

        protoInfo_.morphoAaveV3.maxRiskRatio = VAULT_V2.maxRiskRatio(
            protoInfo_.morphoAaveV3.protocolId
        );

        (
            protoInfo_.morphoAaveV3.rates.wstETHSupplyRate,
            protoInfo_.morphoAaveV3.rates.wETHPoolBorrowRate,
            protoInfo_.morphoAaveV3.rates.wETHP2PBorrowRate,
            protoInfo_.morphoAaveV3.rates.wETHBorrowRate
        ) = getMorphoAaveV3Rates();

        protoInfo_
            .morphoAaveV3
            .rates
            .stETHSupplyRate = convertWstethRateForSteth(
            protoInfo_.morphoAaveV3.rates.wstETHSupplyRate,
            stEthPerWsteth_
        );

        /***********************************|
        |             PROTOCOL 7            |
        |__________________________________*/

        protoInfo_.spark.protocolId = 7;

        (
            protoInfo_.spark.wstETHCol,
            protoInfo_.spark.stETHCol,
            protoInfo_.spark.wETHDebt,
            protoInfo_.spark.ratio // (WETH / STETH)
        ) = VAULT_V2.getRatioSpark(stEthPerWsteth_);

        protoInfo_.spark.maxRiskRatio = VAULT_V2.maxRiskRatio(
            protoInfo_.spark.protocolId
        );

        (
            protoInfo_.spark.rates.wstETHSupplyRate,
            protoInfo_.spark.rates.wETHBorrowRate
        ) = getSparkRates();

        protoInfo_.spark.rates.stETHSupplyRate = convertWstethRateForSteth(
            protoInfo_.spark.rates.wstETHSupplyRate,
            stEthPerWsteth_
        );
    }

    /// @notice Returns all the necessary information of a user.
    function getUserInfo(
        address user_
    )
        public
        view
        returns (
            uint256 userStETHBal_,
            uint256 userItokenV2Bal_,
            uint256 userVaultV2BalInSteth_ // Net asset amount deposited
        )
    {
        userStETHBal_ = IERC20Upgradeable(STETH_ADDRESS).balanceOf(user_);
        userItokenV2Bal_ = VAULT_V2.balanceOf(user_);
        userVaultV2BalInSteth_ =
            (userItokenV2Bal_ * VAULT_V2.exchangePrice()) /
            1e18;
    }

    struct UIInfo {
        // Vault Info
        uint256 availableAaveV2;
        uint256 availableAaveV3;
        uint256 availableCompoundV3;
        uint256 availableEuler;
        uint256 availableMorphoAaveV2;
        uint256 availableMorphoAaveV3;
        uint256 availableSpark;
        uint256 availableWithdrawTotal;
        VaultInfo vaultInfo;
        // Protocols Info
        ProtocolInfo protoInfo;
        uint256 stEthPerWsteth;
        uint256 wstEthPerSteth;
        // User Info
        uint256 userStETHBal;
        uint256 userItokenV2Bal;
        uint256 userVaultV2BalInSteth;
        // V1 Vault Info for import
        uint256 v1ITokenBalance;
        uint256 v1ExchangePrice;
        uint256 v1AssetBalance;
    }

    function getUIDetails(
        address user_
    ) public view returns (UIInfo memory uiInfo_) {
        VaultV2Interface.NetAssetsHelper memory assets_;

        /***********************************|
        |             VAULT INFO            |
        |__________________________________*/
        uiInfo_.vaultInfo = getVaultInfo();

        /***********************************|
        |           PROTOCOLS INFO          |
        |__________________________________*/
        (
            uiInfo_.protoInfo,
            uiInfo_.stEthPerWsteth,
            uiInfo_.wstEthPerSteth
        ) = getAllProtocolInfo();

        /***********************************|
        |             USER INFO             |
        |__________________________________*/
        (
            uiInfo_.userStETHBal,
            uiInfo_.userItokenV2Bal,
            uiInfo_.userVaultV2BalInSteth
        ) = getUserInfo(user_);

        /***********************************|
        |           V1 IMPORT INFO          |
        |__________________________________*/
        uiInfo_.v1ITokenBalance = IERC20Upgradeable(IETH_TOKEN_V1).balanceOf(
            user_
        );
        (uiInfo_.v1ExchangePrice, ) = ILiteVaultV1(IETH_TOKEN_V1)
            .getCurrentExchangePrice();

        /***********************************|
        |    AVAILABLE FOR WITHDARW INFO    |
        |__________________________________*/
        uiInfo_ = availableWithdrawInProtocols(uiInfo_);

        uiInfo_.availableWithdrawTotal =
            uiInfo_.availableAaveV2 +
            uiInfo_.availableAaveV3 +
            uiInfo_.availableCompoundV3 +
            uiInfo_.availableEuler +
            uiInfo_.availableMorphoAaveV2 +
            uiInfo_.availableMorphoAaveV3 +
            uiInfo_.availableSpark +
            assets_.vaultBalances.stETH +
            assets_.vaultBalances.wETH +
            assets_.dsaBalances.stETH +
            assets_.dsaBalances.wETH;
    }

    /// @notice Returns all the amounts available to withdraw in each protocol.
    function availableWithdrawInProtocols(
        UIInfo memory uiInfo_
    ) internal pure returns (UIInfo memory) {
        // in 1e6
        uint256 ratioDiffAaveV2_ = uiInfo_.protoInfo.aaveV2.ratio <
            uiInfo_.protoInfo.aaveV2.maxRiskRatio // we can set buffer margin on backend.
            ? uiInfo_.protoInfo.aaveV2.maxRiskRatio -
                uiInfo_.protoInfo.aaveV2.ratio
            : 0;

        // in 1e6
        uint256 ratioDiffAaveV3_ = uiInfo_.protoInfo.aaveV3.ratio <
            uiInfo_.protoInfo.aaveV3.maxRiskRatio // we can set buffer margin on backend.
            ? uiInfo_.protoInfo.aaveV3.maxRiskRatio -
                uiInfo_.protoInfo.aaveV3.ratio
            : 0;

        // in 1e6
        uint256 ratioDiffCompoundV3_ = uiInfo_.protoInfo.compoundV3.ratio <
            uiInfo_.protoInfo.compoundV3.maxRiskRatio // we can set buffer margin on backend.
            ? uiInfo_.protoInfo.compoundV3.maxRiskRatio -
                uiInfo_.protoInfo.compoundV3.ratio
            : 0;

        // in 1e6
        uint256 ratioDiffEuler_ = uiInfo_.protoInfo.euler.ratio <
            uiInfo_.protoInfo.euler.maxRiskRatio // we can set buffer margin on backend.
            ? uiInfo_.protoInfo.euler.maxRiskRatio -
                uiInfo_.protoInfo.euler.ratio
            : 0;

        // in 1e6
        uint256 ratioDiffmorphoAaveV2_ = uiInfo_.protoInfo.morphoAaveV2.ratio <
            uiInfo_.protoInfo.morphoAaveV2.maxRiskRatio // we can set buffer margin on backend.
            ? uiInfo_.protoInfo.morphoAaveV2.maxRiskRatio -
                uiInfo_.protoInfo.morphoAaveV2.ratio
            : 0;

        // in 1e6
        uint256 ratioDiffMorphoAaveV3_ = uiInfo_.protoInfo.morphoAaveV3.ratio <
            uiInfo_.protoInfo.morphoAaveV3.maxRiskRatio // we can set buffer margin on backend.
            ? uiInfo_.protoInfo.morphoAaveV3.maxRiskRatio -
                uiInfo_.protoInfo.morphoAaveV3.ratio
            : 0;

        // in 1e6
        uint256 ratioDiffSpark_ = uiInfo_.protoInfo.spark.ratio <
            uiInfo_.protoInfo.spark.maxRiskRatio // we can set buffer margin on backend.
            ? uiInfo_.protoInfo.spark.maxRiskRatio -
                uiInfo_.protoInfo.spark.ratio
            : 0;

        // Below calculations are done assuming STETH 1:1 ETH.
        uiInfo_.availableAaveV2 = uiInfo_.protoInfo.aaveV2.maxRiskRatio == 0
            ? uiInfo_.protoInfo.aaveV2.stETHCol
            : (uiInfo_.protoInfo.aaveV2.stETHCol * ratioDiffAaveV2_) /
                uiInfo_.protoInfo.aaveV2.maxRiskRatio;

        uiInfo_.availableAaveV3 = uiInfo_.protoInfo.aaveV3.maxRiskRatio == 0
            ? uiInfo_.protoInfo.aaveV3.stETHCol
            : (uiInfo_.protoInfo.aaveV3.stETHCol * ratioDiffAaveV3_) /
                uiInfo_.protoInfo.aaveV3.maxRiskRatio;

        uiInfo_.availableCompoundV3 = uiInfo_
            .protoInfo
            .compoundV3
            .maxRiskRatio == 0
            ? uiInfo_.protoInfo.compoundV3.stETHCol
            : (uiInfo_.protoInfo.compoundV3.stETHCol * ratioDiffCompoundV3_) /
                uiInfo_.protoInfo.compoundV3.maxRiskRatio;

        uiInfo_.availableEuler = uiInfo_.protoInfo.euler.maxRiskRatio == 0
            ? uiInfo_.protoInfo.euler.stETHCol
            : (uiInfo_.protoInfo.euler.stETHCol * ratioDiffEuler_) /
                uiInfo_.protoInfo.euler.maxRiskRatio;

        uiInfo_.availableMorphoAaveV2 = uiInfo_
            .protoInfo
            .morphoAaveV2
            .maxRiskRatio == 0
            ? uiInfo_.protoInfo.morphoAaveV2.stETHCol
            : (uiInfo_.protoInfo.morphoAaveV2.stETHCol *
                ratioDiffmorphoAaveV2_) /
                uiInfo_.protoInfo.morphoAaveV2.maxRiskRatio;

        uiInfo_.availableMorphoAaveV3 = uiInfo_
            .protoInfo
            .morphoAaveV3
            .maxRiskRatio == 0
            ? uiInfo_.protoInfo.morphoAaveV3.stETHCol
            : (uiInfo_.protoInfo.morphoAaveV3.stETHCol *
                ratioDiffMorphoAaveV3_) /
                uiInfo_.protoInfo.morphoAaveV3.maxRiskRatio;

        uiInfo_.availableSpark = uiInfo_.protoInfo.spark.maxRiskRatio == 0
            ? uiInfo_.protoInfo.spark.stETHCol
            : (uiInfo_.protoInfo.spark.stETHCol * ratioDiffSpark_) /
                uiInfo_.protoInfo.spark.maxRiskRatio;

        return uiInfo_;
    }

    // Returns price in 8 decimals.
    function getPricesInUsd()
        public
        view
        returns (uint256 wstethInUsd, uint256 stethInUsd, uint256 ethInUsd)
    {
        ethInUsd = uint256(ETH_IN_USD.latestAnswer());
        stethInUsd = (uint256(STETH_IN_ETH.latestAnswer()) * ethInUsd) / 1e8;
        wstethInUsd =
            (uint256(WSTETH_CONTRACT.tokensPerStEth()) * stethInUsd) /
            1e18;
    }

    /// @notice gets all withdrawal requests for vault
    /// @dev requestId can be used to get amount of claimable ether with Lido contract WithdrawalQueue:
    /// getClaimableEther()
    /// @return requestIds_ Lido withdrawal request ids
    function getEthWithdrawalRequests()
        external
        view
        returns (uint256[] memory requestIds_)
    {
        return LIDO_WITHDRAWAL_QUEUE.getWithdrawalRequests(address(this));
    }

    /// @notice Returns statuses for the array of request ids
    /// @param requestIds_ array of withdrawal request ids
    function getWithdrawalData(
        uint256[] calldata requestIds_
    )
        external
        view
        returns (
            ILidoWithdrawalQueue.WithdrawalRequestStatus[]
                memory requestStatuses_
        )
    {
        requestStatuses_ = LIDO_WITHDRAWAL_QUEUE.getWithdrawalStatus(
            requestIds_
        );
    }

    /// @notice Returns amount of ether available for claim for each provided request id
    /// @param requestIds_ array of request ids
    /// @return claimableEthValues_ amount of claimable ether for each request, amount is equal to 0 if request
    ///  is not finalized or already claimed
    function getClaimableEther(
        uint256[] calldata requestIds_
    ) external view returns (uint256[] memory claimableEthValues_) {
        uint256[] memory hintIds_ = LIDO_WITHDRAWAL_QUEUE.findCheckpointHints(
            requestIds_,
            1,
            LIDO_WITHDRAWAL_QUEUE.getLastCheckpointIndex()
        );

        claimableEthValues_ = LIDO_WITHDRAWAL_QUEUE.getClaimableEther(
            requestIds_,
            hintIds_
        );
    }
}
