// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

/// @title Struct used across various interfaces in IPOR Protocol.
library IporTypes {
    /// @notice enum describing Swap's state, ACTIVE - when the swap is opened, INACTIVE when it's closed
    enum SwapState {
        INACTIVE,
        ACTIVE
    }

    /// @notice enum describing Swap's duration, 28 days, 60 days or 90 days
    enum SwapTenor {
        DAYS_28,
        DAYS_60,
        DAYS_90
    }

    /// @notice The struct describing the IPOR and its params calculated for the time when it was most recently updated and the change that took place since the update.
    /// Namely, the interest that would be computed into IBT should the rebalance occur.
    struct  AccruedIpor {
        /// @notice IPOR Index Value
        /// @dev value represented in 18 decimals
        uint256 indexValue;
        /// @notice IBT Price (IBT - Interest Bearing Token). For more information refer to the documentation:
        /// https://ipor-labs.gitbook.io/ipor-labs/interest-rate-derivatives/ibt
        /// @dev value represented in 18 decimals
        uint256 ibtPrice;
    }

    /// @notice Struct representing balances used internally for asset calculations
    /// @dev all balances in 18 decimals
    struct AmmBalancesMemory {
        /// @notice Sum of all collateral put forward by the derivative buyer's on  Pay Fixed & Receive Floating leg.
        uint256 totalCollateralPayFixed;
        /// @notice Sum of all collateral put forward by the derivative buyer's on  Pay Floating & Receive Fixed leg.
        uint256 totalCollateralReceiveFixed;
        /// @notice Liquidity Pool Balance. This balance is where the liquidity from liquidity providers and the opening fee are accounted for,
        /// @dev Amount of opening fee accounted in this balance is defined by _OPENING_FEE_FOR_TREASURY_PORTION_RATE param.
        uint256 liquidityPool;
        /// @notice Vault's balance, describes how much asset has been transferred to Asset Management Vault (AssetManagement)
        uint256 vault;
    }

    struct AmmBalancesForOpenSwapMemory {
        /// @notice Sum of all collateral put forward by the derivative buyer's on  Pay Fixed & Receive Floating leg.
        uint256 totalCollateralPayFixed;
        /// @notice Total notional amount of all swaps on  Pay Fixed leg (denominated in 18 decimals).
        uint256 totalNotionalPayFixed;
        /// @notice Sum of all collateral put forward by the derivative buyer's on  Pay Floating & Receive Fixed leg.
        uint256 totalCollateralReceiveFixed;
        /// @notice Total notional amount of all swaps on  Receive Fixed leg (denominated in 18 decimals).
        uint256 totalNotionalReceiveFixed;
        /// @notice Liquidity Pool Balance.
        uint256 liquidityPool;
    }

    struct SpreadInputs {
        //// @notice Swap's assets DAI/USDC/USDT
        address asset;
        /// @notice Swap's notional value
        uint256 swapNotional;
        /// @notice demand spread factor used in demand spread calculation
        uint256 demandSpreadFactor;
        /// @notice Base spread
        int256 baseSpreadPerLeg;
        /// @notice Swap's balance for Pay Fixed leg
        uint256 totalCollateralPayFixed;
        /// @notice Swap's balance for Receive Fixed leg
        uint256 totalCollateralReceiveFixed;
        /// @notice Liquidity Pool's Balance
        uint256 liquidityPoolBalance;
        /// @notice Ipor index value at the time of swap creation
        uint256 iporIndexValue;
        // @notice fixed rate cap for given leg for offered rate without demandSpread in 18 decimals
        uint256 fixedRateCapPerLeg;
    }
}

/// @title Types used in interfaces strictly related to AMM (Automated Market Maker).
/// @dev Used by IAmmTreasury and IAmmStorage interfaces.
library AmmTypes {
    /// @notice Struct describing AMM Pool's core addresses.
    struct AmmPoolCoreModel {
        /// @notice asset address
        address asset;
        /// @notice asset decimals
        uint256 assetDecimals;
        /// @notice ipToken address associated to the asset
        address ipToken;
        /// @notice AMM Storage address
        address ammStorage;
        /// @notice AMM Treasury address
        address ammTreasury;
        /// @notice Asset Management address
        address assetManagement;
        /// @notice IPOR Oracle address
        address iporOracle;
        /// @notice IPOR Risk Management Oracle address
        address iporRiskManagementOracle;
    }

    /// @notice Structure which represents Swap's data that will be saved in the storage.
    /// Refer to the documentation https://ipor-labs.gitbook.io/ipor-labs/automated-market-maker/ipor-swaps for more information.
    struct NewSwap {
        /// @notice Account / trader who opens the Swap
        address buyer;
        /// @notice Epoch timestamp of when position was opened by the trader.
        uint256 openTimestamp;
        /// @notice Swap's collateral amount.
        /// @dev value represented in 18 decimals
        uint256 collateral;
        /// @notice Swap's notional amount.
        /// @dev value represented in 18 decimals
        uint256 notional;
        /// @notice Quantity of Interest Bearing Token (IBT) at moment when position was opened.
        /// @dev value represented in 18 decimals
        uint256 ibtQuantity;
        /// @notice Fixed interest rate at which the position has been opened.
        /// @dev value represented in 18 decimals
        uint256 fixedInterestRate;
        /// @notice Liquidation deposit is retained when the swap is opened. It is then paid back to agent who closes the derivative at maturity.
        /// It can be both trader or community member. Trader receives the deposit back when he chooses to close the derivative before maturity.
        /// @dev value represented WITHOUT 18 decimals
        uint256 liquidationDepositAmount;
        /// @notice Opening fee amount part which is allocated in Liquidity Pool Balance. This fee is calculated as a rate of the swap's collateral.
        /// @dev value represented in 18 decimals
        uint256 openingFeeLPAmount;
        /// @notice Opening fee amount part which is allocated in Treasury Balance. This fee is calculated as a rate of the swap's collateral.
        /// @dev value represented in 18 decimals
        uint256 openingFeeTreasuryAmount;
        /// @notice Swap's tenor, 0 - 28 days, 1 - 60 days or 2 - 90 days
        IporTypes.SwapTenor tenor;
    }

    /// @notice Struct representing swap item, used for listing and in internal calculations
    struct Swap {
        /// @notice Swap's unique ID
        uint256 id;
        /// @notice Swap's buyer
        address buyer;
        /// @notice Swap opening epoch timestamp
        uint256 openTimestamp;
        /// @notice Swap's tenor
        IporTypes.SwapTenor tenor;
        /// @notice Index position of this Swap in an array of swaps' identification associated to swap buyer
        /// @dev Field used for gas optimization purposes, it allows for quick removal by id in the array.
        /// During removal the last item in the array is switched with the one that just has been removed.
        uint256 idsIndex;
        /// @notice Swap's collateral
        /// @dev value represented in 18 decimals
        uint256 collateral;
        /// @notice Swap's notional amount
        /// @dev value represented in 18 decimals
        uint256 notional;
        /// @notice Swap's notional amount denominated in the Interest Bearing Token (IBT)
        /// @dev value represented in 18 decimals
        uint256 ibtQuantity;
        /// @notice Fixed interest rate at which the position has been opened
        /// @dev value represented in 18 decimals
        uint256 fixedInterestRate;
        /// @notice Liquidation deposit amount
        /// @dev value represented in 18 decimals
        uint256 liquidationDepositAmount;
        /// @notice State of the swap
        /// @dev 0 - INACTIVE, 1 - ACTIVE
        IporTypes.SwapState state;
    }

    /// @notice Struct representing amounts related to Swap that is presently being opened.
    /// @dev all values represented in 18 decimals
    struct OpenSwapAmount {
        /// @notice Total Amount of asset that is sent from buyer to AmmTreasury when opening swap.
        uint256 totalAmount;
        /// @notice Swap's collateral
        uint256 collateral;
        /// @notice Swap's notional
        uint256 notional;
        /// @notice Opening Fee - part allocated as a profit of the Liquidity Pool
        uint256 openingFeeLPAmount;
        /// @notice  Part of the fee set aside for subsidizing the oracle that publishes IPOR rate. Flat fee set by the DAO.
        /// @notice Opening Fee - part allocated in Treasury balance. Part of the fee set asside for subsidising the oracle that publishes IPOR rate. Flat fee set by the DAO.
        uint256 openingFeeTreasuryAmount;
        /// @notice Fee set aside for subsidizing the oracle that publishes IPOR rate. Flat fee set by the DAO.
        uint256 iporPublicationFee;
        /// @notice Liquidation deposit is retained when the swap is opened. Value represented in 18 decimals.
        uint256 liquidationDepositAmount;
    }

    /// @notice Structure describes one swap processed by closeSwaps method, information about swap ID and flag if this swap was closed during execution closeSwaps method.
    struct IporSwapClosingResult {
        /// @notice Swap ID
        uint256 swapId;
        /// @notice Flag describe if swap was closed during this execution
        bool closed;
    }

    /// @notice Technical structure used for storing information about amounts used during redeeming assets from liquidity pool.
    struct RedeemAmount {
        /// @notice Asset amount represented in 18 decimals
        /// @dev Asset amount is a sum of wadRedeemFee and wadRedeemAmount
        uint256 wadAssetAmount;
        /// @notice Redeemed amount represented in decimals of asset
        uint256 redeemAmount;
        /// @notice Redeem fee value represented in 18 decimals
        uint256 wadRedeemFee;
        /// @notice Redeem amount represented in 18 decimals
        uint256 wadRedeemAmount;
    }

    /// @notice Swap direction (long = Pay Fixed and Receive a Floating or short = receive fixed and pay a floating)
    enum SwapDirection {
        /// @notice When taking the "long" position the trader will pay a fixed rate and receive a floating rate.
        /// for more information refer to the documentation https://ipor-labs.gitbook.io/ipor-labs/automated-market-maker/ipor-swaps
        PAY_FIXED_RECEIVE_FLOATING,
        /// @notice When taking the "short" position the trader will pay a floating rate and receive a fixed rate.
        PAY_FLOATING_RECEIVE_FIXED
    }
    /// @notice List of closable statuses for a given swap
    /// @dev Closable status is a one of the following values:
    /// 0 - Swap is closable
    /// 1 - Swap is already closed
    /// 2 - Swap state required Buyer or Liquidator to close. Sender is not Buyer nor Liquidator.
    /// 3 - Cannot close swap, closing is too early for Community
    enum SwapClosableStatus {
        SWAP_IS_CLOSABLE,
        SWAP_ALREADY_CLOSED,
        SWAP_REQUIRED_BUYER_OR_LIQUIDATOR_TO_CLOSE,
        SWAP_CANNOT_CLOSE_CLOSING_TOO_EARLY_FOR_COMMUNITY
    }

    /// @notice Collection of swap attributes connected with IPOR Index and swap itself.
    /// @dev all values are in 18 decimals
    struct IporSwapIndicator {
        /// @notice IPOR Index value at the time of swap opening
        uint256 iporIndexValue;
        /// @notice IPOR Interest Bearing Token (IBT) price at the time of swap opening
        uint256 ibtPrice;
        /// @notice Swap's notional denominated in IBT
        uint256 ibtQuantity;
        /// @notice Fixed interest rate at which the position has been opened,
        /// it is quote from spread documentation
        uint256 fixedInterestRate;
    }

    /// @notice Risk indicators calculated for swap opening
    struct OpenSwapRiskIndicators {
        /// @notice Maximum collateral ratio in general
        uint256 maxCollateralRatio;
        /// @notice Maximum collateral ratio for a given leg
        uint256 maxCollateralRatioPerLeg;
        /// @notice Maximum leverage for a given leg
        uint256 maxLeveragePerLeg;
        /// @notice Base Spread for a given leg (without demand part)
        int256 baseSpreadPerLeg;
        /// @notice Fixed rate cap
        uint256 fixedRateCapPerLeg;
        /// @notice Demand spread factor used to calculate demand spread
        uint256 demandSpreadFactor;
    }

    /// @notice Structure containing information about swap's closing status, unwind values and PnL for a given swap and time.
    struct ClosingSwapDetails {
        /// @notice Swap's closing status
        AmmTypes.SwapClosableStatus closableStatus;
        /// @notice Flag indicating if swap unwind is required
        bool swapUnwindRequired;
        /// @notice Swap's unwind PnL Value, part of PnL corresponded to virtual swap (unwinded swap), represented in 18 decimals
        int256 swapUnwindPnlValue;
        /// @notice Unwind opening fee amount it is a sum of `swapUnwindFeeLPAmount` and `swapUnwindFeeTreasuryAmount`
        uint256 swapUnwindOpeningFeeAmount;
        /// @notice Part of unwind opening fee allocated as a profit of the Liquidity Pool
        uint256 swapUnwindFeeLPAmount;
        /// @notice Part of unwind opening fee allocated in Treasury Balance
        uint256 swapUnwindFeeTreasuryAmount;
        /// @notice Final Profit and Loss which takes into account the swap unwind and limits the PnL to the collateral amount. Represented in 18 decimals.
        int256 pnlValue;
    }
}

/// @title Types used in AmmStorage smart contract
library AmmStorageTypes {
    /// @notice struct representing swap's ID and direction
    /// @dev direction = 0 - Pay Fixed - Receive Floating, direction = 1 - Receive Fixed - Pay Floating
    struct IporSwapId {
        /// @notice Swap's ID
        uint256 id;
        /// @notice Swap's direction, 0 - Pay Fixed Receive Floating, 1 - Receive Fixed Pay Floating
        uint8 direction;
    }

    /// @notice Struct containing extended balance information.
    /// @dev extended information includes: opening fee balance, liquidation deposit balance,
    /// IPOR publication fee balance, treasury balance, all values are with 18 decimals
    struct ExtendedBalancesMemory {
        /// @notice Swap's balance for Pay Fixed leg
        uint256 totalCollateralPayFixed;
        /// @notice Swap's balance for Receive Fixed leg
        uint256 totalCollateralReceiveFixed;
        /// @notice Liquidity Pool's Balance
        uint256 liquidityPool;
        /// @notice AssetManagement's (Asset Management) balance
        uint256 vault;
        /// @notice IPOR publication fee balance. This balance is used to subsidise the oracle operations
        uint256 iporPublicationFee;
        /// @notice Balance of the DAO's treasury. Fed by portion of the opening fee set by the DAO
        uint256 treasury;
    }

    /// @notice A struct with parameters required to calculate SOAP for pay fixed and receive fixed legs.
    /// @dev Committed to the memory.
    struct SoapIndicators {
        /// @notice Value of interest accrued on a fixed leg of all derivatives for this particular type of swap.
        /// @dev Represented in 18 decimals.
        uint256 hypotheticalInterestCumulative;
        /// @notice Sum of all swaps' notional amounts for a given leg.
        /// @dev Represented in 18 decimals.
        uint256 totalNotional;
        /// @notice Sum of all IBTs on a given leg.
        /// @dev Represented in 18 decimals.
        uint256 totalIbtQuantity;
        /// @notice The notional-weighted average interest rate of all swaps on a given leg combined.
        /// @dev Represented in 18 decimals.
        uint256 averageInterestRate;
        /// @notice EPOCH timestamp of when the most recent rebalancing took place
        uint256 rebalanceTimestamp;
    }
}

/// @notice The types used in the AmmTreasury's interface.
/// @dev All values, where applicable, are represented in 18 decimals.
library AmmInternalTypes {
    struct PnlValueStruct    {
        /// @notice PnL Value of the swap.
        int256 pnlValue;
        /// @notice flag indicating if unwind is required when closing swap.
        bool swapUnwindRequired;
        /// @notice Unwind amount of the swap.
        int256 swapUnwindAmount;
        /// @notice Unwind fee of the swap that will be added to the AMM liquidity pool balance.
        uint256 swapUnwindFeeLPAmount;
        /// @notice Unwind fee of the swap that will be added to the AMM treasury balance.
        uint256 swapUnwindFeeTreasuryAmount;
    }

    struct BeforeOpenSwapStruct {
        /// @notice Sum of all asset transfered when opening swap. It includes the collateral, fees and desposits.
        /// @dev The amount is represented in 18 decimals regardless of the decimals of the asset.
        uint256 wadTotalAmount;
        /// @notice Swap's collateral.
        uint256 collateral;
        /// @notice Swap's notional amount.
        uint256 notional;
        /// @notice The part of the opening fee that will be added to the liquidity pool balance.
        uint256 openingFeeLPAmount;
        /// @notice Part of the opening fee that will be added to the treasury balance.
        uint256 openingFeeTreasuryAmount;
        /// @notice Amount of asset set aside for the oracle subsidization.
        uint256 iporPublicationFeeAmount;
        /// @notice Refundable deposit blocked for the entity that will close the swap.
        /// For more information on how the liquidations work refer to the documentation.
        /// https://ipor-labs.gitbook.io/ipor-labs/automated-market-maker/liquidations
        /// @dev value represented without decimals, as an integer
        uint256 liquidationDepositAmount;
        /// @notice The struct describing the IPOR and its params calculated for the time when it was most recently updated and the change that took place since the update.
        /// Namely, the interest that would be computed into IBT should the rebalance occur.
        IporTypes.AccruedIpor accruedIpor;
    }

    /// @notice Risk indicators context data
    struct RiskIndicatorsContext {
        /// @notice Asset address for which the risk indicators are calculated.
        address asset;
        /// @notice Ipor Risk Management Oracle address.
        address iporRiskManagementOracle;
        /// @notice Tenor of the swap.
        IporTypes.SwapTenor tenor;
        /// @notice AMM Liquidity Pool balance.
        uint256 liquidityPoolBalance;
        /// @notice AMM Min Leverage allowed for a swap.
        uint256 minLeverage;
    }

    /// @notice Spread context data
    struct SpreadContext {
        /// @notice Asset address for which the spread is calculated.
        address asset;
        /// @notice Signature of spread method used to calculate spread.
        bytes4 spreadFunctionSig;
        /// @notice Tenor of the swap.
        IporTypes.SwapTenor tenor;
        /// @notice Swap's notional
        uint256 notional;
        /// @notice Minimum leverage allowed for a swap.
        uint256 minLeverage;
        /// @notice Ipor Index Value
        uint256 indexValue;
        /// @notice Risk Indicators data for a opened swap used to calculate spread.
        AmmTypes.OpenSwapRiskIndicators riskIndicators;
        /// @notice AMM Balance for a opened swap used to calculate spread.
        IporTypes.AmmBalancesForOpenSwapMemory balance;
    }

    /// @notice Open swap item - element of linked list of swaps
    struct OpenSwapItem {
        /// @notice Swap ID
        uint32 swapId;
        /// @notcie Next swap ID in linked list
        uint32 nextSwapId;
        /// @notice Previous swap ID in linked list
        uint32 previousSwapId;
        /// @notice Timestamp of the swap opening
        uint32 openSwapTimestamp;
    }

    /// @notice Open swap list structure
    struct OpenSwapList {
        /// @notice Head swap ID
        uint32 headSwapId;
        /// @notice Swaps mapping, where key is swap ID
        mapping(uint32 => OpenSwapItem) swaps;
    }
}

/// @title Interface for interaction with the IPOR AMM Storage, contract responsible for managing AMM storage.
interface IAmmStorage {
    /// @notice Returns the current version of AmmTreasury Storage
    /// @dev Increase number when the implementation inside source code is different that the implementation deployed on the Mainnet
    /// @return current AmmTreasury Storage version, integer
    function getVersion() external pure returns (uint256);

    /// @notice Gets the configuration of the IPOR AMM Storage.
    /// @return ammTreasury address of the AmmTreasury contract
    /// @return router address of the IPOR Protocol Router contract
    function getConfiguration() external view returns (address ammTreasury, address router);

    /// @notice Gets last swap ID.
    /// @dev swap ID is incremented when new position is opened, last swap ID is used in Pay Fixed and Receive Fixed swaps.
    /// @dev ID is global for all swaps, regardless if they are Pay Fixed or Receive Fixed in tenor 28, 60 or 90 days.
    /// @return last swap ID, integer
    function getLastSwapId() external view returns (uint256);

    /// @notice Gets the last opened swap for a given tenor and direction.
    /// @param tenor tenor of the swap
    /// @param direction direction of the swap: 0 for Pay Fixed, 1 for Receive Fixed
    /// @return last opened swap {AmmInternalTypes.OpenSwapItem}
    function getLastOpenedSwap(
        IporTypes.SwapTenor tenor,
        uint256 direction
    ) external view returns (AmmInternalTypes.OpenSwapItem memory);

    /// @notice Gets the AMM balance struct
    /// @dev Balance contains:
    /// # Pay Fixed Total Collateral
    /// # Receive Fixed Total Collateral
    /// # Liquidity Pool and Vault balances.
    /// @return balance structure {IporTypes.AmmBalancesMemory}
    function getBalance() external view returns (IporTypes.AmmBalancesMemory memory);

    /// @notice Gets the balance for open swap
    /// @dev Balance contains:
    /// # Pay Fixed Total Collateral
    /// # Receive Fixed Total Collateral
    /// # Liquidity Pool balance
    /// # Total Notional Pay Fixed
    /// # Total Notional Receive Fixed
    /// @return balance structure {IporTypes.AmmBalancesForOpenSwapMemory}
    function getBalancesForOpenSwap() external view returns (IporTypes.AmmBalancesForOpenSwapMemory memory);

    /// @notice Gets the balance with the extended information: IPOR publication fee balance and Treasury balance.
    /// @return balance structure {AmmStorageTypes.ExtendedBalancesMemory}
    function getExtendedBalance() external view returns (AmmStorageTypes.ExtendedBalancesMemory memory);

    /// @notice gets the SOAP indicators.
    /// @dev SOAP is a Sum Of All Payouts, aka undealised PnL.
    /// @return indicatorsPayFixed structure {AmmStorageTypes.SoapIndicators} indicators for Pay Fixed swaps
    /// @return indicatorsReceiveFixed structure {AmmStorageTypes.SoapIndicators} indicators for Receive Fixed swaps
    function getSoapIndicators()
        external
        view
        returns (
            AmmStorageTypes.SoapIndicators memory indicatorsPayFixed,
            AmmStorageTypes.SoapIndicators memory indicatorsReceiveFixed
        );

    /// @notice Gets swap based on the direction and swap ID.
    /// @param direction direction of the swap: 0 for Pay Fixed, 1 for Receive Fixed
    /// @param swapId swap ID
    /// @return swap structure {AmmTypes.Swap}
    function getSwap(AmmTypes.SwapDirection direction, uint256 swapId) external view returns (AmmTypes.Swap memory);

    /// @notice Gets the active Pay-Fixed swaps for a given account address.
    /// @param account account address
    /// @param offset offset for paging
    /// @param chunkSize page size for paging
    /// @return totalCount total number of active Pay-Fixed swaps
    /// @return swaps array where each element has structure {AmmTypes.Swap}
    function getSwapsPayFixed(
        address account,
        uint256 offset,
        uint256 chunkSize
    ) external view returns (uint256 totalCount, AmmTypes.Swap[] memory swaps);

    /// @notice Gets the active Receive-Fixed swaps for a given account address.
    /// @param account account address
    /// @param offset offset for paging
    /// @param chunkSize page size for paging
    /// @return totalCount total number of active Receive Fixed swaps
    /// @return swaps array where each element has structure {AmmTypes.Swap}
    function getSwapsReceiveFixed(
        address account,
        uint256 offset,
        uint256 chunkSize
    ) external view returns (uint256 totalCount, AmmTypes.Swap[] memory swaps);

    /// @notice Gets the active Pay-Fixed and Receive-Fixed swaps IDs for a given account address.
    /// @param account account address
    /// @param offset offset for paging
    /// @param chunkSize page size for paging
    /// @return totalCount total number of active Pay-Fixed and Receive-Fixed IDs.
    /// @return ids array where each element has structure {AmmStorageTypes.IporSwapId}
    function getSwapIds(
        address account,
        uint256 offset,
        uint256 chunkSize
    ) external view returns (uint256 totalCount, AmmStorageTypes.IporSwapId[] memory ids);

    /// @notice adds liquidity to the Liquidity Pool. Function available only to Router.
    /// @param account account address executing request for redeem asset amount
    /// @param assetAmount amount of asset added to balance of Liquidity Pool, represented in 18 decimals
    /// @param cfgMaxLiquidityPoolBalance max liquidity pool balance taken from AmmPoolsService configuration, represented in 18 decimals.
    /// @dev Function is only available to AmmPoolsService, can be executed only by IPOR Protocol Router as internal interaction.
    function addLiquidityInternal(address account, uint256 assetAmount, uint256 cfgMaxLiquidityPoolBalance) external;

    /// @notice subtract liquidity from the Liquidity Pool. Function available only to Router.
    /// @param assetAmount amount of asset subtracted from Liquidity Pool, represented in 18 decimals
    /// @dev Function is only available to AmmPoolsService, it can be executed only by IPOR Protocol Router as internal interaction.
    function subtractLiquidityInternal(uint256 assetAmount) external;

    /// @notice Updates structures in storage: balance, swaps, SOAP indicators when new Pay-Fixed swap is opened.
    /// @dev Function is only available to AmmOpenSwapService, it can be executed only by IPOR Protocol Router as internal interaction.
    /// @param newSwap new swap structure {AmmTypes.NewSwap}
    /// @param cfgIporPublicationFee publication fee amount taken from AmmTreasury configuration, represented in 18 decimals.
    /// @return new swap ID
    function updateStorageWhenOpenSwapPayFixedInternal(
        AmmTypes.NewSwap memory newSwap,
        uint256 cfgIporPublicationFee
    ) external returns (uint256);

    /// @notice Updates structures in the storage: balance, swaps, SOAP indicators when new Receive-Fixed swap is opened.
    /// @dev Function is only available to AmmOpenSwapService, it can be executed only by IPOR Protocol Router as internal interaction.
    /// @param newSwap new swap structure {AmmTypes.NewSwap}
    /// @param cfgIporPublicationFee publication fee amount taken from AmmTreasury configuration, represented in 18 decimals.
    /// @return new swap ID
    function updateStorageWhenOpenSwapReceiveFixedInternal(
        AmmTypes.NewSwap memory newSwap,
        uint256 cfgIporPublicationFee
    ) external returns (uint256);

    /// @notice Updates structures in the storage: balance, swaps, SOAP indicators when closing Pay-Fixed swap.
    /// @dev Function is only available to AmmCloseSwapService, it can be executed only by IPOR Protocol Router as internal interaction.
    /// @param swap The swap structure containing IPOR swap information.
    /// @param pnlValue The amount that the trader has earned or lost on the swap, represented in 18 decimals.
    /// pnValue can be negative, pnlValue NOT INCLUDE potential unwind fee.
    /// @param swapUnwindFeeLPAmount unwind fee which is accounted on AMM Liquidity Pool balance.
    /// @param swapUnwindFeeTreasuryAmount unwind fee which is accounted on AMM Treasury balance.
    /// @param closingTimestamp The moment when the swap was closed.
    /// @return closedSwap A memory struct representing the closed swap.
    function updateStorageWhenCloseSwapPayFixedInternal(
        AmmTypes.Swap memory swap,
        int256 pnlValue,
        uint256 swapUnwindFeeLPAmount,
        uint256 swapUnwindFeeTreasuryAmount,
        uint256 closingTimestamp
    ) external returns (AmmInternalTypes.OpenSwapItem memory closedSwap);

    /// @notice Updates structures in the storage: swaps, balances, SOAP indicators when closing Receive-Fixed swap.
    /// @dev Function is only available to AmmCloseSwapService, it can be executed only by IPOR Protocol Router as internal interaction.
    /// @param swap The swap structure containing IPOR swap information.
    /// @param pnlValue The amount that the trader has earned or lost on the swap, represented in 18 decimals.
    /// pnValue can be negative, pnlValue NOT INCLUDE potential unwind fee.
    /// @param swapUnwindFeeLPAmount unwind fee which is accounted on AMM Liquidity Pool balance.
    /// @param swapUnwindFeeTreasuryAmount unwind fee which is accounted on AMM Treasury balance.
    /// @param closingTimestamp The moment when the swap was closed.
    /// @return closedSwap A memory struct representing the closed swap.
    function updateStorageWhenCloseSwapReceiveFixedInternal(
        AmmTypes.Swap memory swap,
        int256 pnlValue,
        uint256 swapUnwindFeeLPAmount,
        uint256 swapUnwindFeeTreasuryAmount,
        uint256 closingTimestamp
    ) external returns (AmmInternalTypes.OpenSwapItem memory closedSwap);

    /// @notice Updates the balance when the AmmPoolsService withdraws AmmTreasury's assets from the AssetManagement.
    /// @dev Function is only available to the AmmTreasury contract.
    /// @param withdrawnAmount asset amount that was withdrawn from AssetManagement to AmmTreasury by AmmPoolsService, represented in 18 decimals.
    /// @param vaultBalance Asset Management Vault (AssetManagement) balance, represented in 18 decimals
    function updateStorageWhenWithdrawFromAssetManagement(uint256 withdrawnAmount, uint256 vaultBalance) external;

    /// @notice Updates the balance when AmmPoolsService deposits AmmTreasury's assets to AssetManagement. Function is only available to AmmTreasury.
    /// @param depositAmount asset amount deposited from AmmTreasury to AssetManagement by AmmPoolsService, represented in 18 decimals.
    /// @param vaultBalance actual Asset Management Vault(AssetManagement) balance , represented in 18 decimals
    function updateStorageWhenDepositToAssetManagement(uint256 depositAmount, uint256 vaultBalance) external;

    /// @notice Updates the balance when AmmPoolsService transfers AmmTreasury's assets to Oracle Treasury's multisig wallet.
    /// @dev Function is only available to the AmmGovernanceService, can be executed only by IPOR Protocol Router as internal interaction.
    /// @param transferredAmount asset amount transferred to Charlie Treasury multisig wallet.
    function updateStorageWhenTransferToCharlieTreasuryInternal(uint256 transferredAmount) external;

    /// @notice Updates the balance when AmmPoolsService transfers AmmTreasury's assets to Treasury's multisig wallet.
    /// @dev Function is only available to the AmmGovernanceService, can be executed only by IPOR Protocol Router as internal interaction.
    /// @param transferredAmount asset amount transferred to Treasury's multisig wallet.
    function updateStorageWhenTransferToTreasuryInternal(uint256 transferredAmount) external;
}

/// @title Spread interface for close swap, service
interface ISpreadCloseSwapService {
    /// @notice Updates the time-weighted notional on swap closure.
    /// @dev Updates the time-weighted notional for the specified asset and tenor based on the swap closure.
    /// @param asset The address of the asset involved in the swap.
    /// @param direction The direction of the swap: 0 for Pay Fixed, 1 for Receive Fixed.
    /// @param tenor The tenor of the swap.
    /// @param swapNotional The notional amount of the swap.
    /// @param closedSwap The memory struct containing the swap information.
    /// @param ammStorageAddress The address of the AMM storage.
    function updateTimeWeightedNotionalOnClose(
        address asset,
        uint256 direction,
        IporTypes.SwapTenor tenor,
        uint256 swapNotional,
        AmmInternalTypes.OpenSwapItem memory closedSwap,
        address ammStorageAddress
    ) external;
}

library IporErrors {
    // 000-199 - general codes

    /// @notice General problem, address is wrong
    string public constant WRONG_ADDRESS = "IPOR_000";

    /// @notice General problem. Wrong decimals
    string public constant WRONG_DECIMALS = "IPOR_001";

    /// @notice General problem, addresses mismatch
    string public constant ADDRESSES_MISMATCH = "IPOR_002";

    /// @notice Sender's asset balance is too low to transfer and to open a swap
    string public constant SENDER_ASSET_BALANCE_TOO_LOW = "IPOR_003";

    /// @notice Value is not greater than zero
    string public constant VALUE_NOT_GREATER_THAN_ZERO = "IPOR_004";

    /// @notice Input arrays length mismatch
    string public constant INPUT_ARRAYS_LENGTH_MISMATCH = "IPOR_005";

    /// @notice Amount is too low to transfer
    string public constant NOT_ENOUGH_AMOUNT_TO_TRANSFER = "IPOR_006";

    /// @notice msg.sender is not an appointed owner, so cannot confirm his appointment to be an owner of a specific smart contract
    string public constant SENDER_NOT_APPOINTED_OWNER = "IPOR_007";

    /// @notice only Router can have access to function
    string public constant CALLER_NOT_IPOR_PROTOCOL_ROUTER = "IPOR_008";

    /// @notice Chunk size is equal to zero
    string public constant CHUNK_SIZE_EQUAL_ZERO = "IPOR_009";

    /// @notice Chunk size is too big
    string public constant CHUNK_SIZE_TOO_BIG = "IPOR_010";

    /// @notice Caller is not a  guardian
    string public constant CALLER_NOT_GUARDIAN = "IPOR_011";

    /// @notice Request contains invalid method signature, which is not supported by the Ipor Protocol Router
    string public constant ROUTER_INVALID_SIGNATURE = "IPOR_012";

    /// @notice Only AMM Treasury can have access to function
    string public constant CALLER_NOT_AMM_TREASURY = "IPOR_013";

    /// @notice Caller is not an owner
    string public constant CALLER_NOT_OWNER = "IPOR_014";

    /// @notice Method is paused
    string public constant METHOD_PAUSED = "IPOR_015";

    /// @notice Reentrancy appears
    string public constant REENTRANCY = "IPOR_016";

    /// @notice Asset is not supported
    string public constant ASSET_NOT_SUPPORTED = "IPOR_017";

    /// @notice Return back ETH failed in Ipor Protocol Router
    string public constant ROUTER_RETURN_BACK_ETH_FAILED = "IPOR_018";
}

/// @title Errors which occur inside AmmTreasury's method execution.
library AmmErrors {
    // 300-399-AMM
    /// @notice Liquidity Pool balance is equal 0.
    string public constant LIQUIDITY_POOL_IS_EMPTY = "IPOR_300";

    /// @notice Liquidity Pool balance is too low, should be equal or higher than 0.
    string public constant LIQUIDITY_POOL_AMOUNT_TOO_LOW = "IPOR_301";

    /// @notice Liquidity Pool Collateral Ratio exceeded. Liquidity Pool Collateral Ratio is higher than configured in AmmTreasury maximum liquidity pool collateral ratio.
    string public constant LP_COLLATERAL_RATIO_EXCEEDED = "IPOR_302";

    /// @notice Liquidity Pool Collateral Ratio Per Leg exceeded. Liquidity Pool Collateral Ratio per leg is higher than configured in AmmTreasury maximum liquidity pool collateral ratio per leg.
    string public constant LP_COLLATERAL_RATIO_PER_LEG_EXCEEDED = "IPOR_303";

    /// @notice Liquidity Pool Balance is too high
    string public constant LIQUIDITY_POOL_BALANCE_IS_TOO_HIGH = "IPOR_304";

    /// @notice Swap cannot be closed because liquidity pool is too low for payid out cash. Situation should never happen where Liquidity Pool is insolvent.
    string public constant CANNOT_CLOSE_SWAP_LP_IS_TOO_LOW = "IPOR_305";

    /// @notice Swap id used in input has incorrect value (like 0) or not exists.
    string public constant INCORRECT_SWAP_ID = "IPOR_306";

    /// @notice Swap has incorrect status.
    string public constant INCORRECT_SWAP_STATUS = "IPOR_307";

    /// @notice Leverage given as a parameter when opening swap is lower than configured in AmmTreasury minimum leverage.
    string public constant LEVERAGE_TOO_LOW = "IPOR_308";

    /// @notice Leverage given as a parameter when opening swap is higher than configured in AmmTreasury maxumum leverage.
    string public constant LEVERAGE_TOO_HIGH = "IPOR_309";

    /// @notice Total amount given as a parameter when opening swap is too low. Cannot be equal zero.
    string public constant TOTAL_AMOUNT_TOO_LOW = "IPOR_310";

    /// @notice Total amount given as a parameter when opening swap is lower than sum of liquidation deposit amount and ipor publication fee.
    string public constant TOTAL_AMOUNT_LOWER_THAN_FEE = "IPOR_311";

    /// @notice Amount of collateral used to open swap is higher than configured in AmmTreasury max swap collateral amount
    string public constant COLLATERAL_AMOUNT_TOO_HIGH = "IPOR_312";

    /// @notice Acceptable fixed interest rate defined by traded exceeded.
    string public constant ACCEPTABLE_FIXED_INTEREST_RATE_EXCEEDED = "IPOR_313";

    /// @notice Swap Notional Amount is higher than Total Notional for specific leg.
    string public constant SWAP_NOTIONAL_HIGHER_THAN_TOTAL_NOTIONAL = "IPOR_314";

    /// @notice Number of swaps per leg which are going to be liquidated is too high, is higher than configured in AmmTreasury liquidation leg limit.
    string public constant MAX_LENGTH_LIQUIDATED_SWAPS_PER_LEG_EXCEEDED = "IPOR_315";

    /// @notice Sum of SOAP and Liquidity Pool Balance is lower than zero.
    /// @dev SOAP can be negative, Sum of SOAP and Liquidity Pool Balance can be negative, but this is undesirable.
    string public constant SOAP_AND_LP_BALANCE_SUM_IS_TOO_LOW = "IPOR_316";

    /// @notice Calculation timestamp is earlier than last SOAP rebalance timestamp.
    string public constant CALC_TIMESTAMP_LOWER_THAN_SOAP_REBALANCE_TIMESTAMP = "IPOR_317";

    /// @notice Calculation timestamp is lower than  Swap's open timestamp.
    string public constant CALC_TIMESTAMP_LOWER_THAN_SWAP_OPEN_TIMESTAMP = "IPOR_318";

    /// @notice Closing timestamp is lower than Swap's open timestamp.
    string public constant CLOSING_TIMESTAMP_LOWER_THAN_SWAP_OPEN_TIMESTAMP = "IPOR_319";

    /// @notice Swap cannot be closed because sender is not a buyer nor liquidator.
    string public constant CANNOT_CLOSE_SWAP_SENDER_IS_NOT_BUYER_NOR_LIQUIDATOR = "IPOR_320";

    /// @notice Interest from Strategy is below zero.
    string public constant INTEREST_FROM_STRATEGY_EXCEEDED_THRESHOLD = "IPOR_321";

    /// @notice IPOR publication fee balance is too low.
    string public constant PUBLICATION_FEE_BALANCE_IS_TOO_LOW = "IPOR_322";

    /// @notice The caller must be the Token Manager (Smart Contract responsible for managing token total supply).
    string public constant CALLER_NOT_TOKEN_MANAGER = "IPOR_323";

    /// @notice Deposit amount is too low.
    string public constant DEPOSIT_AMOUNT_IS_TOO_LOW = "IPOR_324";

    /// @notice Vault balance is lower than deposit value.
    string public constant VAULT_BALANCE_LOWER_THAN_DEPOSIT_VALUE = "IPOR_325";

    /// @notice Treasury balance is too low.
    string public constant TREASURY_BALANCE_IS_TOO_LOW = "IPOR_326";

    /// @notice Swap cannot be closed because closing timestamp is lower than swap's open timestamp in general.
    string public constant CANNOT_CLOSE_SWAP_CLOSING_IS_TOO_EARLY = "IPOR_327";

    /// @notice Swap cannot be closed because closing timestamp is lower than swap's open timestamp for buyer.
    string public constant CANNOT_CLOSE_SWAP_CLOSING_IS_TOO_EARLY_FOR_BUYER = "IPOR_328";

    /// @notice Swap cannot be closed and unwind because is too late
    string public constant CANNOT_UNWIND_CLOSING_TOO_LATE = "IPOR_329";

    /// @notice Unsupported swap tenor
    string public constant UNSUPPORTED_SWAP_TENOR = "IPOR_330";

    /// @notice Sender is not AMM (is not a IporProtocolRouter contract)
    string public constant SENDER_NOT_AMM = "IPOR_331";

    /// @notice Storage id is not time weighted notional group
    string public constant STORAGE_ID_IS_NOT_TIME_WEIGHTED_NOTIONAL = "IPOR_332";

    /// @notice Spread function is not supported
    string public constant FUNCTION_NOT_SUPPORTED = "IPOR_333";

    /// @notice Unsupported direction
    string public constant UNSUPPORTED_DIRECTION = "IPOR_334";

    /// @notice Invalid notional
    string public constant INVALID_NOTIONAL = "IPOR_335";

    /// @notice Average interest rate cannot be zero when open swap
    string public constant AVERAGE_INTEREST_RATE_WHEN_OPEN_SWAP_CANNOT_BE_ZERO = "IPOR_336";

    /// @notice Average interest rate cannot be zero when close swap
    string public constant AVERAGE_INTEREST_RATE_WHEN_CLOSE_SWAP_CANNOT_BE_ZERO = "IPOR_337";

    /// @notice Submit ETH to stETH contract failed.
    string public constant STETH_SUBMIT_FAILED = "IPOR_338";

    /// @notice Collateral is not sufficient to cover unwind swap
    string public constant COLLATERAL_IS_NOT_SUFFICIENT_TO_COVER_UNWIND_SWAP = "IPOR_339";

    /// @notice Error when withdraw from asset management is not enough to cover transfer amount to buyer and/or beneficiary
    string public constant ASSET_MANAGEMENT_WITHDRAW_NOT_ENOUGH = "IPOR_340";
}

library IporContractValidator {
    function checkAddress(address addr) internal pure returns (address) {
        require(addr != address(0), IporErrors.WRONG_ADDRESS);
        return addr;
    }
}

// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/SafeCast.sol)
// This file was procedurally generated from scripts/generate/templates/SafeCast.js.

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {
    /**
     * @dev Returns the downcasted uint248 from uint256, reverting on
     * overflow (when the input is greater than largest uint248).
     *
     * Counterpart to Solidity's `uint248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    function toUint248(uint256 value) internal pure returns (uint248) {
        require(value <= type(uint248).max, "SafeCast: value doesn't fit in 248 bits");
        return uint248(value);
    }

    /**
     * @dev Returns the downcasted uint240 from uint256, reverting on
     * overflow (when the input is greater than largest uint240).
     *
     * Counterpart to Solidity's `uint240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     *
     * _Available since v4.7._
     */
    function toUint240(uint256 value) internal pure returns (uint240) {
        require(value <= type(uint240).max, "SafeCast: value doesn't fit in 240 bits");
        return uint240(value);
    }

    /**
     * @dev Returns the downcasted uint232 from uint256, reverting on
     * overflow (when the input is greater than largest uint232).
     *
     * Counterpart to Solidity's `uint232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     *
     * _Available since v4.7._
     */
    function toUint232(uint256 value) internal pure returns (uint232) {
        require(value <= type(uint232).max, "SafeCast: value doesn't fit in 232 bits");
        return uint232(value);
    }

    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     *
     * _Available since v4.2._
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint216 from uint256, reverting on
     * overflow (when the input is greater than largest uint216).
     *
     * Counterpart to Solidity's `uint216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     *
     * _Available since v4.7._
     */
    function toUint216(uint256 value) internal pure returns (uint216) {
        require(value <= type(uint216).max, "SafeCast: value doesn't fit in 216 bits");
        return uint216(value);
    }

    /**
     * @dev Returns the downcasted uint208 from uint256, reverting on
     * overflow (when the input is greater than largest uint208).
     *
     * Counterpart to Solidity's `uint208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     *
     * _Available since v4.7._
     */
    function toUint208(uint256 value) internal pure returns (uint208) {
        require(value <= type(uint208).max, "SafeCast: value doesn't fit in 208 bits");
        return uint208(value);
    }

    /**
     * @dev Returns the downcasted uint200 from uint256, reverting on
     * overflow (when the input is greater than largest uint200).
     *
     * Counterpart to Solidity's `uint200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     *
     * _Available since v4.7._
     */
    function toUint200(uint256 value) internal pure returns (uint200) {
        require(value <= type(uint200).max, "SafeCast: value doesn't fit in 200 bits");
        return uint200(value);
    }

    /**
     * @dev Returns the downcasted uint192 from uint256, reverting on
     * overflow (when the input is greater than largest uint192).
     *
     * Counterpart to Solidity's `uint192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     *
     * _Available since v4.7._
     */
    function toUint192(uint256 value) internal pure returns (uint192) {
        require(value <= type(uint192).max, "SafeCast: value doesn't fit in 192 bits");
        return uint192(value);
    }

    /**
     * @dev Returns the downcasted uint184 from uint256, reverting on
     * overflow (when the input is greater than largest uint184).
     *
     * Counterpart to Solidity's `uint184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     *
     * _Available since v4.7._
     */
    function toUint184(uint256 value) internal pure returns (uint184) {
        require(value <= type(uint184).max, "SafeCast: value doesn't fit in 184 bits");
        return uint184(value);
    }

    /**
     * @dev Returns the downcasted uint176 from uint256, reverting on
     * overflow (when the input is greater than largest uint176).
     *
     * Counterpart to Solidity's `uint176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     *
     * _Available since v4.7._
     */
    function toUint176(uint256 value) internal pure returns (uint176) {
        require(value <= type(uint176).max, "SafeCast: value doesn't fit in 176 bits");
        return uint176(value);
    }

    /**
     * @dev Returns the downcasted uint168 from uint256, reverting on
     * overflow (when the input is greater than largest uint168).
     *
     * Counterpart to Solidity's `uint168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     *
     * _Available since v4.7._
     */
    function toUint168(uint256 value) internal pure returns (uint168) {
        require(value <= type(uint168).max, "SafeCast: value doesn't fit in 168 bits");
        return uint168(value);
    }

    /**
     * @dev Returns the downcasted uint160 from uint256, reverting on
     * overflow (when the input is greater than largest uint160).
     *
     * Counterpart to Solidity's `uint160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     *
     * _Available since v4.7._
     */
    function toUint160(uint256 value) internal pure returns (uint160) {
        require(value <= type(uint160).max, "SafeCast: value doesn't fit in 160 bits");
        return uint160(value);
    }

    /**
     * @dev Returns the downcasted uint152 from uint256, reverting on
     * overflow (when the input is greater than largest uint152).
     *
     * Counterpart to Solidity's `uint152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     *
     * _Available since v4.7._
     */
    function toUint152(uint256 value) internal pure returns (uint152) {
        require(value <= type(uint152).max, "SafeCast: value doesn't fit in 152 bits");
        return uint152(value);
    }

    /**
     * @dev Returns the downcasted uint144 from uint256, reverting on
     * overflow (when the input is greater than largest uint144).
     *
     * Counterpart to Solidity's `uint144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     *
     * _Available since v4.7._
     */
    function toUint144(uint256 value) internal pure returns (uint144) {
        require(value <= type(uint144).max, "SafeCast: value doesn't fit in 144 bits");
        return uint144(value);
    }

    /**
     * @dev Returns the downcasted uint136 from uint256, reverting on
     * overflow (when the input is greater than largest uint136).
     *
     * Counterpart to Solidity's `uint136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     *
     * _Available since v4.7._
     */
    function toUint136(uint256 value) internal pure returns (uint136) {
        require(value <= type(uint136).max, "SafeCast: value doesn't fit in 136 bits");
        return uint136(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v2.5._
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint120 from uint256, reverting on
     * overflow (when the input is greater than largest uint120).
     *
     * Counterpart to Solidity's `uint120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     *
     * _Available since v4.7._
     */
    function toUint120(uint256 value) internal pure returns (uint120) {
        require(value <= type(uint120).max, "SafeCast: value doesn't fit in 120 bits");
        return uint120(value);
    }

    /**
     * @dev Returns the downcasted uint112 from uint256, reverting on
     * overflow (when the input is greater than largest uint112).
     *
     * Counterpart to Solidity's `uint112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     *
     * _Available since v4.7._
     */
    function toUint112(uint256 value) internal pure returns (uint112) {
        require(value <= type(uint112).max, "SafeCast: value doesn't fit in 112 bits");
        return uint112(value);
    }

    /**
     * @dev Returns the downcasted uint104 from uint256, reverting on
     * overflow (when the input is greater than largest uint104).
     *
     * Counterpart to Solidity's `uint104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     *
     * _Available since v4.7._
     */
    function toUint104(uint256 value) internal pure returns (uint104) {
        require(value <= type(uint104).max, "SafeCast: value doesn't fit in 104 bits");
        return uint104(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     *
     * _Available since v4.2._
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint88 from uint256, reverting on
     * overflow (when the input is greater than largest uint88).
     *
     * Counterpart to Solidity's `uint88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     *
     * _Available since v4.7._
     */
    function toUint88(uint256 value) internal pure returns (uint88) {
        require(value <= type(uint88).max, "SafeCast: value doesn't fit in 88 bits");
        return uint88(value);
    }

    /**
     * @dev Returns the downcasted uint80 from uint256, reverting on
     * overflow (when the input is greater than largest uint80).
     *
     * Counterpart to Solidity's `uint80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toUint80(uint256 value) internal pure returns (uint80) {
        require(value <= type(uint80).max, "SafeCast: value doesn't fit in 80 bits");
        return uint80(value);
    }

    /**
     * @dev Returns the downcasted uint72 from uint256, reverting on
     * overflow (when the input is greater than largest uint72).
     *
     * Counterpart to Solidity's `uint72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     *
     * _Available since v4.7._
     */
    function toUint72(uint256 value) internal pure returns (uint72) {
        require(value <= type(uint72).max, "SafeCast: value doesn't fit in 72 bits");
        return uint72(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v2.5._
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint56 from uint256, reverting on
     * overflow (when the input is greater than largest uint56).
     *
     * Counterpart to Solidity's `uint56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     *
     * _Available since v4.7._
     */
    function toUint56(uint256 value) internal pure returns (uint56) {
        require(value <= type(uint56).max, "SafeCast: value doesn't fit in 56 bits");
        return uint56(value);
    }

    /**
     * @dev Returns the downcasted uint48 from uint256, reverting on
     * overflow (when the input is greater than largest uint48).
     *
     * Counterpart to Solidity's `uint48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     *
     * _Available since v4.7._
     */
    function toUint48(uint256 value) internal pure returns (uint48) {
        require(value <= type(uint48).max, "SafeCast: value doesn't fit in 48 bits");
        return uint48(value);
    }

    /**
     * @dev Returns the downcasted uint40 from uint256, reverting on
     * overflow (when the input is greater than largest uint40).
     *
     * Counterpart to Solidity's `uint40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     *
     * _Available since v4.7._
     */
    function toUint40(uint256 value) internal pure returns (uint40) {
        require(value <= type(uint40).max, "SafeCast: value doesn't fit in 40 bits");
        return uint40(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v2.5._
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint24 from uint256, reverting on
     * overflow (when the input is greater than largest uint24).
     *
     * Counterpart to Solidity's `uint24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     *
     * _Available since v4.7._
     */
    function toUint24(uint256 value) internal pure returns (uint24) {
        require(value <= type(uint24).max, "SafeCast: value doesn't fit in 24 bits");
        return uint24(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v2.5._
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits
     *
     * _Available since v2.5._
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     *
     * _Available since v3.0._
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int248 from int256, reverting on
     * overflow (when the input is less than smallest int248 or
     * greater than largest int248).
     *
     * Counterpart to Solidity's `int248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    function toInt248(int256 value) internal pure returns (int248 downcasted) {
        downcasted = int248(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 248 bits");
    }

    /**
     * @dev Returns the downcasted int240 from int256, reverting on
     * overflow (when the input is less than smallest int240 or
     * greater than largest int240).
     *
     * Counterpart to Solidity's `int240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     *
     * _Available since v4.7._
     */
    function toInt240(int256 value) internal pure returns (int240 downcasted) {
        downcasted = int240(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 240 bits");
    }

    /**
     * @dev Returns the downcasted int232 from int256, reverting on
     * overflow (when the input is less than smallest int232 or
     * greater than largest int232).
     *
     * Counterpart to Solidity's `int232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     *
     * _Available since v4.7._
     */
    function toInt232(int256 value) internal pure returns (int232 downcasted) {
        downcasted = int232(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 232 bits");
    }

    /**
     * @dev Returns the downcasted int224 from int256, reverting on
     * overflow (when the input is less than smallest int224 or
     * greater than largest int224).
     *
     * Counterpart to Solidity's `int224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     *
     * _Available since v4.7._
     */
    function toInt224(int256 value) internal pure returns (int224 downcasted) {
        downcasted = int224(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 224 bits");
    }

    /**
     * @dev Returns the downcasted int216 from int256, reverting on
     * overflow (when the input is less than smallest int216 or
     * greater than largest int216).
     *
     * Counterpart to Solidity's `int216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     *
     * _Available since v4.7._
     */
    function toInt216(int256 value) internal pure returns (int216 downcasted) {
        downcasted = int216(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 216 bits");
    }

    /**
     * @dev Returns the downcasted int208 from int256, reverting on
     * overflow (when the input is less than smallest int208 or
     * greater than largest int208).
     *
     * Counterpart to Solidity's `int208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     *
     * _Available since v4.7._
     */
    function toInt208(int256 value) internal pure returns (int208 downcasted) {
        downcasted = int208(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 208 bits");
    }

    /**
     * @dev Returns the downcasted int200 from int256, reverting on
     * overflow (when the input is less than smallest int200 or
     * greater than largest int200).
     *
     * Counterpart to Solidity's `int200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     *
     * _Available since v4.7._
     */
    function toInt200(int256 value) internal pure returns (int200 downcasted) {
        downcasted = int200(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 200 bits");
    }

    /**
     * @dev Returns the downcasted int192 from int256, reverting on
     * overflow (when the input is less than smallest int192 or
     * greater than largest int192).
     *
     * Counterpart to Solidity's `int192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     *
     * _Available since v4.7._
     */
    function toInt192(int256 value) internal pure returns (int192 downcasted) {
        downcasted = int192(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 192 bits");
    }

    /**
     * @dev Returns the downcasted int184 from int256, reverting on
     * overflow (when the input is less than smallest int184 or
     * greater than largest int184).
     *
     * Counterpart to Solidity's `int184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     *
     * _Available since v4.7._
     */
    function toInt184(int256 value) internal pure returns (int184 downcasted) {
        downcasted = int184(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 184 bits");
    }

    /**
     * @dev Returns the downcasted int176 from int256, reverting on
     * overflow (when the input is less than smallest int176 or
     * greater than largest int176).
     *
     * Counterpart to Solidity's `int176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     *
     * _Available since v4.7._
     */
    function toInt176(int256 value) internal pure returns (int176 downcasted) {
        downcasted = int176(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 176 bits");
    }

    /**
     * @dev Returns the downcasted int168 from int256, reverting on
     * overflow (when the input is less than smallest int168 or
     * greater than largest int168).
     *
     * Counterpart to Solidity's `int168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     *
     * _Available since v4.7._
     */
    function toInt168(int256 value) internal pure returns (int168 downcasted) {
        downcasted = int168(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 168 bits");
    }

    /**
     * @dev Returns the downcasted int160 from int256, reverting on
     * overflow (when the input is less than smallest int160 or
     * greater than largest int160).
     *
     * Counterpart to Solidity's `int160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     *
     * _Available since v4.7._
     */
    function toInt160(int256 value) internal pure returns (int160 downcasted) {
        downcasted = int160(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 160 bits");
    }

    /**
     * @dev Returns the downcasted int152 from int256, reverting on
     * overflow (when the input is less than smallest int152 or
     * greater than largest int152).
     *
     * Counterpart to Solidity's `int152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     *
     * _Available since v4.7._
     */
    function toInt152(int256 value) internal pure returns (int152 downcasted) {
        downcasted = int152(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 152 bits");
    }

    /**
     * @dev Returns the downcasted int144 from int256, reverting on
     * overflow (when the input is less than smallest int144 or
     * greater than largest int144).
     *
     * Counterpart to Solidity's `int144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     *
     * _Available since v4.7._
     */
    function toInt144(int256 value) internal pure returns (int144 downcasted) {
        downcasted = int144(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 144 bits");
    }

    /**
     * @dev Returns the downcasted int136 from int256, reverting on
     * overflow (when the input is less than smallest int136 or
     * greater than largest int136).
     *
     * Counterpart to Solidity's `int136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     *
     * _Available since v4.7._
     */
    function toInt136(int256 value) internal pure returns (int136 downcasted) {
        downcasted = int136(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 136 bits");
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128 downcasted) {
        downcasted = int128(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 128 bits");
    }

    /**
     * @dev Returns the downcasted int120 from int256, reverting on
     * overflow (when the input is less than smallest int120 or
     * greater than largest int120).
     *
     * Counterpart to Solidity's `int120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     *
     * _Available since v4.7._
     */
    function toInt120(int256 value) internal pure returns (int120 downcasted) {
        downcasted = int120(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 120 bits");
    }

    /**
     * @dev Returns the downcasted int112 from int256, reverting on
     * overflow (when the input is less than smallest int112 or
     * greater than largest int112).
     *
     * Counterpart to Solidity's `int112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     *
     * _Available since v4.7._
     */
    function toInt112(int256 value) internal pure returns (int112 downcasted) {
        downcasted = int112(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 112 bits");
    }

    /**
     * @dev Returns the downcasted int104 from int256, reverting on
     * overflow (when the input is less than smallest int104 or
     * greater than largest int104).
     *
     * Counterpart to Solidity's `int104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     *
     * _Available since v4.7._
     */
    function toInt104(int256 value) internal pure returns (int104 downcasted) {
        downcasted = int104(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 104 bits");
    }

    /**
     * @dev Returns the downcasted int96 from int256, reverting on
     * overflow (when the input is less than smallest int96 or
     * greater than largest int96).
     *
     * Counterpart to Solidity's `int96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     *
     * _Available since v4.7._
     */
    function toInt96(int256 value) internal pure returns (int96 downcasted) {
        downcasted = int96(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 96 bits");
    }

    /**
     * @dev Returns the downcasted int88 from int256, reverting on
     * overflow (when the input is less than smallest int88 or
     * greater than largest int88).
     *
     * Counterpart to Solidity's `int88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     *
     * _Available since v4.7._
     */
    function toInt88(int256 value) internal pure returns (int88 downcasted) {
        downcasted = int88(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 88 bits");
    }

    /**
     * @dev Returns the downcasted int80 from int256, reverting on
     * overflow (when the input is less than smallest int80 or
     * greater than largest int80).
     *
     * Counterpart to Solidity's `int80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toInt80(int256 value) internal pure returns (int80 downcasted) {
        downcasted = int80(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 80 bits");
    }

    /**
     * @dev Returns the downcasted int72 from int256, reverting on
     * overflow (when the input is less than smallest int72 or
     * greater than largest int72).
     *
     * Counterpart to Solidity's `int72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     *
     * _Available since v4.7._
     */
    function toInt72(int256 value) internal pure returns (int72 downcasted) {
        downcasted = int72(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 72 bits");
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64 downcasted) {
        downcasted = int64(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 64 bits");
    }

    /**
     * @dev Returns the downcasted int56 from int256, reverting on
     * overflow (when the input is less than smallest int56 or
     * greater than largest int56).
     *
     * Counterpart to Solidity's `int56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     *
     * _Available since v4.7._
     */
    function toInt56(int256 value) internal pure returns (int56 downcasted) {
        downcasted = int56(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 56 bits");
    }

    /**
     * @dev Returns the downcasted int48 from int256, reverting on
     * overflow (when the input is less than smallest int48 or
     * greater than largest int48).
     *
     * Counterpart to Solidity's `int48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     *
     * _Available since v4.7._
     */
    function toInt48(int256 value) internal pure returns (int48 downcasted) {
        downcasted = int48(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 48 bits");
    }

    /**
     * @dev Returns the downcasted int40 from int256, reverting on
     * overflow (when the input is less than smallest int40 or
     * greater than largest int40).
     *
     * Counterpart to Solidity's `int40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     *
     * _Available since v4.7._
     */
    function toInt40(int256 value) internal pure returns (int40 downcasted) {
        downcasted = int40(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 40 bits");
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32 downcasted) {
        downcasted = int32(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 32 bits");
    }

    /**
     * @dev Returns the downcasted int24 from int256, reverting on
     * overflow (when the input is less than smallest int24 or
     * greater than largest int24).
     *
     * Counterpart to Solidity's `int24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     *
     * _Available since v4.7._
     */
    function toInt24(int256 value) internal pure returns (int24 downcasted) {
        downcasted = int24(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 24 bits");
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16 downcasted) {
        downcasted = int16(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 16 bits");
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8 downcasted) {
        downcasted = int8(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 8 bits");
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     *
     * _Available since v3.0._
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

library IporMath {
    uint256 private constant RAY = 1e27;

    //@notice Division with rounding up on last position, x, and y is with MD
    function division(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = (x + (y / 2)) / y;
    }

    function divisionInt(int256 x, int256 y) internal pure returns (int256 z) {
        uint256 absX = uint256(x < 0 ? -x : x);
        uint256 absY = uint256(y < 0 ? -y : y);

        // Use bitwise XOR to get the sign on MBS bit then shift to LSB
        // sign == 0x0000...0000 ==  0 if the number is non-negative
        // sign == 0xFFFF...FFFF == -1 if the number is negative
        int256 sign = (x ^ y) >> 255;

        uint256 divAbs;
        uint256 remainder;

        unchecked {
            divAbs = absX / absY;
            remainder = absX % absY;
        }
        // Check if we need to round
        if (sign < 0) {
            // remainder << 1 left shift is equivalent to multiplying by 2
            if (remainder << 1 > absY) {
                ++divAbs;
            }
        } else {
            if (remainder << 1 >= absY) {
                ++divAbs;
            }
        }

        // (sign | 1) is cheaper than (sign < 0) ? -1 : 1;
        unchecked {
            z = int256(divAbs) * (sign | 1);
        }
    }

    function divisionWithoutRound(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x / y;
    }

    function convertWadToAssetDecimals(uint256 value, uint256 assetDecimals) internal pure returns (uint256) {
        if (assetDecimals == 18) {
            return value;
        } else if (assetDecimals > 18) {
            return value * 10 ** (assetDecimals - 18);
        } else {
            return division(value, 10 ** (18 - assetDecimals));
        }
    }

    function convertWadToAssetDecimalsWithoutRound(
        uint256 value,
        uint256 assetDecimals
    ) internal pure returns (uint256) {
        if (assetDecimals == 18) {
            return value;
        } else if (assetDecimals > 18) {
            return value * 10 ** (assetDecimals - 18);
        } else {
            return divisionWithoutRound(value, 10 ** (18 - assetDecimals));
        }
    }

    function convertToWad(uint256 value, uint256 assetDecimals) internal pure returns (uint256) {
        if (value > 0) {
            if (assetDecimals == 18) {
                return value;
            } else if (assetDecimals > 18) {
                return division(value, 10 ** (assetDecimals - 18));
            } else {
                return value * 10 ** (18 - assetDecimals);
            }
        } else {
            return value;
        }
    }

    function absoluteValue(int256 value) internal pure returns (uint256) {
        return (uint256)(value < 0 ? -value : value);
    }

    function percentOf(uint256 value, uint256 rate) internal pure returns (uint256) {
        return division(value * rate, 1e18);
    }

    /// @notice Calculates x^n where x and y are represented in RAY (27 decimals)
    /// @param x base, represented in 27 decimals
    /// @param n exponent, represented in 27 decimals
    /// @return z x^n represented in 27 decimals
    function rayPow(uint256 x, uint256 n) internal pure returns (uint256 z) {
        assembly {
            switch x
            case 0 {
                switch n
                case 0 {
                    z := RAY
                }
                default {
                    z := 0
                }
            }
            default {
                switch mod(n, 2)
                case 0 {
                    z := RAY
                }
                default {
                    z := x
                }
                let half := div(RAY, 2) // for rounding.
                for {
                    n := div(n, 2)
                } n {
                    n := div(n, 2)
                } {
                    let xx := mul(x, x)
                    if iszero(eq(div(xx, x), x)) {
                        revert(0, 0)
                    }
                    let xxRound := add(xx, half)
                    if lt(xxRound, xx) {
                        revert(0, 0)
                    }
                    x := div(xxRound, RAY)
                    if mod(n, 2) {
                        let zx := mul(z, x)
                        if and(iszero(iszero(x)), iszero(eq(div(zx, x), z))) {
                            revert(0, 0)
                        }
                        let zxRound := add(zx, half)
                        if lt(zxRound, zx) {
                            revert(0, 0)
                        }
                        z := div(zxRound, RAY)
                    }
                }
            }
        }
    }
}

/*
 * ABDK Math Quad Smart Contract Library.  Copyright © 2019 by ABDK Consulting.
 * Author: Mikhail Vladimirov <mikhail.vladimirov@gmail.com>
 */

/**
 * Smart contract library of mathematical functions operating with IEEE 754
 * quadruple-precision binary floating-point numbers (quadruple precision
 * numbers).  As long as quadruple precision numbers are 16-bytes long, they are
 * represented by bytes16 type.
 */
library ABDKMathQuad {
  /*
   * 0.
   */
  bytes16 private constant POSITIVE_ZERO = 0x00000000000000000000000000000000;

  /*
   * -0.
   */
  bytes16 private constant NEGATIVE_ZERO = 0x80000000000000000000000000000000;

  /*
   * +Infinity.
   */
  bytes16 private constant POSITIVE_INFINITY = 0x7FFF0000000000000000000000000000;

  /*
   * -Infinity.
   */
  bytes16 private constant NEGATIVE_INFINITY = 0xFFFF0000000000000000000000000000;

  /*
   * Canonical NaN value.
   */
  bytes16 private constant NaN = 0x7FFF8000000000000000000000000000;

  /**
   * Convert signed 256-bit integer number into quadruple precision number.
   *
   * @param x signed 256-bit integer number
   * @return quadruple precision number
   */
  function fromInt (int256 x) internal pure returns (bytes16) {
    unchecked {
      if (x == 0) return bytes16 (0);
      else {
        // We rely on overflow behavior here
        uint256 result = uint256 (x > 0 ? x : -x);

        uint256 msb = mostSignificantBit (result);
        if (msb < 112) result <<= 112 - msb;
        else if (msb > 112) result >>= msb - 112;

        result = result & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF | 16383 + msb << 112;
        if (x < 0) result |= 0x80000000000000000000000000000000;

        return bytes16 (uint128 (result));
      }
    }
  }

  /**
   * Convert quadruple precision number into signed 256-bit integer number
   * rounding towards zero.  Revert on overflow.
   *
   * @param x quadruple precision number
   * @return signed 256-bit integer number
   */
  function toInt (bytes16 x) internal pure returns (int256) {
    unchecked {
      uint256 exponent = uint128 (x) >> 112 & 0x7FFF;

      require (exponent <= 16638); // Overflow
      if (exponent < 16383) return 0; // Underflow

      uint256 result = uint256 (uint128 (x)) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF |
        0x10000000000000000000000000000;

      if (exponent < 16495) result >>= 16495 - exponent;
      else if (exponent > 16495) result <<= exponent - 16495;

      if (uint128 (x) >= 0x80000000000000000000000000000000) { // Negative
        require (result <= 0x8000000000000000000000000000000000000000000000000000000000000000);
        return -int256 (result); // We rely on overflow behavior here
      } else {
        require (result <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
        return int256 (result);
      }
    }
  }

  /**
   * Convert unsigned 256-bit integer number into quadruple precision number.
   *
   * @param x unsigned 256-bit integer number
   * @return quadruple precision number
   */
  function fromUInt (uint256 x) internal pure returns (bytes16) {
    unchecked {
      if (x == 0) return bytes16 (0);
      else {
        uint256 result = x;

        uint256 msb = mostSignificantBit (result);
        if (msb < 112) result <<= 112 - msb;
        else if (msb > 112) result >>= msb - 112;

        result = result & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF | 16383 + msb << 112;

        return bytes16 (uint128 (result));
      }
    }
  }

  /**
   * Convert quadruple precision number into unsigned 256-bit integer number
   * rounding towards zero.  Revert on underflow.  Note, that negative floating
   * point numbers in range (-1.0 .. 0.0) may be converted to unsigned integer
   * without error, because they are rounded to zero.
   *
   * @param x quadruple precision number
   * @return unsigned 256-bit integer number
   */
  function toUInt (bytes16 x) internal pure returns (uint256) {
    unchecked {
      uint256 exponent = uint128 (x) >> 112 & 0x7FFF;

      if (exponent < 16383) return 0; // Underflow

      require (uint128 (x) < 0x80000000000000000000000000000000); // Negative

      require (exponent <= 16638); // Overflow
      uint256 result = uint256 (uint128 (x)) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF |
        0x10000000000000000000000000000;

      if (exponent < 16495) result >>= 16495 - exponent;
      else if (exponent > 16495) result <<= exponent - 16495;

      return result;
    }
  }

  /**
   * Convert signed 128.128 bit fixed point number into quadruple precision
   * number.
   *
   * @param x signed 128.128 bit fixed point number
   * @return quadruple precision number
   */
  function from128x128 (int256 x) internal pure returns (bytes16) {
    unchecked {
      if (x == 0) return bytes16 (0);
      else {
        // We rely on overflow behavior here
        uint256 result = uint256 (x > 0 ? x : -x);

        uint256 msb = mostSignificantBit (result);
        if (msb < 112) result <<= 112 - msb;
        else if (msb > 112) result >>= msb - 112;

        result = result & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF | 16255 + msb << 112;
        if (x < 0) result |= 0x80000000000000000000000000000000;

        return bytes16 (uint128 (result));
      }
    }
  }

  /**
   * Convert quadruple precision number into signed 128.128 bit fixed point
   * number.  Revert on overflow.
   *
   * @param x quadruple precision number
   * @return signed 128.128 bit fixed point number
   */
  function to128x128 (bytes16 x) internal pure returns (int256) {
    unchecked {
      uint256 exponent = uint128 (x) >> 112 & 0x7FFF;

      require (exponent <= 16510); // Overflow
      if (exponent < 16255) return 0; // Underflow

      uint256 result = uint256 (uint128 (x)) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF |
        0x10000000000000000000000000000;

      if (exponent < 16367) result >>= 16367 - exponent;
      else if (exponent > 16367) result <<= exponent - 16367;

      if (uint128 (x) >= 0x80000000000000000000000000000000) { // Negative
        require (result <= 0x8000000000000000000000000000000000000000000000000000000000000000);
        return -int256 (result); // We rely on overflow behavior here
      } else {
        require (result <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
        return int256 (result);
      }
    }
  }

  /**
   * Convert signed 64.64 bit fixed point number into quadruple precision
   * number.
   *
   * @param x signed 64.64 bit fixed point number
   * @return quadruple precision number
   */
  function from64x64 (int128 x) internal pure returns (bytes16) {
    unchecked {
      if (x == 0) return bytes16 (0);
      else {
        // We rely on overflow behavior here
        uint256 result = uint128 (x > 0 ? x : -x);

        uint256 msb = mostSignificantBit (result);
        if (msb < 112) result <<= 112 - msb;
        else if (msb > 112) result >>= msb - 112;

        result = result & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF | 16319 + msb << 112;
        if (x < 0) result |= 0x80000000000000000000000000000000;

        return bytes16 (uint128 (result));
      }
    }
  }

  /**
   * Convert quadruple precision number into signed 64.64 bit fixed point
   * number.  Revert on overflow.
   *
   * @param x quadruple precision number
   * @return signed 64.64 bit fixed point number
   */
  function to64x64 (bytes16 x) internal pure returns (int128) {
    unchecked {
      uint256 exponent = uint128 (x) >> 112 & 0x7FFF;

      require (exponent <= 16446); // Overflow
      if (exponent < 16319) return 0; // Underflow

      uint256 result = uint256 (uint128 (x)) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF |
        0x10000000000000000000000000000;

      if (exponent < 16431) result >>= 16431 - exponent;
      else if (exponent > 16431) result <<= exponent - 16431;

      if (uint128 (x) >= 0x80000000000000000000000000000000) { // Negative
        require (result <= 0x80000000000000000000000000000000);
        return -int128 (int256 (result)); // We rely on overflow behavior here
      } else {
        require (result <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
        return int128 (int256 (result));
      }
    }
  }

  /**
   * Convert octuple precision number into quadruple precision number.
   *
   * @param x octuple precision number
   * @return quadruple precision number
   */
  function fromOctuple (bytes32 x) internal pure returns (bytes16) {
    unchecked {
      bool negative = x & 0x8000000000000000000000000000000000000000000000000000000000000000 > 0;

      uint256 exponent = uint256 (x) >> 236 & 0x7FFFF;
      uint256 significand = uint256 (x) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

      if (exponent == 0x7FFFF) {
        if (significand > 0) return NaN;
        else return negative ? NEGATIVE_INFINITY : POSITIVE_INFINITY;
      }

      if (exponent > 278526)
        return negative ? NEGATIVE_INFINITY : POSITIVE_INFINITY;
      else if (exponent < 245649)
        return negative ? NEGATIVE_ZERO : POSITIVE_ZERO;
      else if (exponent < 245761) {
        significand = (significand | 0x100000000000000000000000000000000000000000000000000000000000) >> 245885 - exponent;
        exponent = 0;
      } else {
        significand >>= 124;
        exponent -= 245760;
      }

      uint128 result = uint128 (significand | exponent << 112);
      if (negative) result |= 0x80000000000000000000000000000000;

      return bytes16 (result);
    }
  }

  /**
   * Convert quadruple precision number into octuple precision number.
   *
   * @param x quadruple precision number
   * @return octuple precision number
   */
  function toOctuple (bytes16 x) internal pure returns (bytes32) {
    unchecked {
      uint256 exponent = uint128 (x) >> 112 & 0x7FFF;

      uint256 result = uint128 (x) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

      if (exponent == 0x7FFF) exponent = 0x7FFFF; // Infinity or NaN
      else if (exponent == 0) {
        if (result > 0) {
          uint256 msb = mostSignificantBit (result);
          result = result << 236 - msb & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
          exponent = 245649 + msb;
        }
      } else {
        result <<= 124;
        exponent += 245760;
      }

      result |= exponent << 236;
      if (uint128 (x) >= 0x80000000000000000000000000000000)
        result |= 0x8000000000000000000000000000000000000000000000000000000000000000;

      return bytes32 (result);
    }
  }

  /**
   * Convert double precision number into quadruple precision number.
   *
   * @param x double precision number
   * @return quadruple precision number
   */
  function fromDouble (bytes8 x) internal pure returns (bytes16) {
    unchecked {
      uint256 exponent = uint64 (x) >> 52 & 0x7FF;

      uint256 result = uint64 (x) & 0xFFFFFFFFFFFFF;

      if (exponent == 0x7FF) exponent = 0x7FFF; // Infinity or NaN
      else if (exponent == 0) {
        if (result > 0) {
          uint256 msb = mostSignificantBit (result);
          result = result << 112 - msb & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
          exponent = 15309 + msb;
        }
      } else {
        result <<= 60;
        exponent += 15360;
      }

      result |= exponent << 112;
      if (x & 0x8000000000000000 > 0)
        result |= 0x80000000000000000000000000000000;

      return bytes16 (uint128 (result));
    }
  }

  /**
   * Convert quadruple precision number into double precision number.
   *
   * @param x quadruple precision number
   * @return double precision number
   */
  function toDouble (bytes16 x) internal pure returns (bytes8) {
    unchecked {
      bool negative = uint128 (x) >= 0x80000000000000000000000000000000;

      uint256 exponent = uint128 (x) >> 112 & 0x7FFF;
      uint256 significand = uint128 (x) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

      if (exponent == 0x7FFF) {
        if (significand > 0) return 0x7FF8000000000000; // NaN
        else return negative ?
            bytes8 (0xFFF0000000000000) : // -Infinity
            bytes8 (0x7FF0000000000000); // Infinity
      }

      if (exponent > 17406)
        return negative ?
            bytes8 (0xFFF0000000000000) : // -Infinity
            bytes8 (0x7FF0000000000000); // Infinity
      else if (exponent < 15309)
        return negative ?
            bytes8 (0x8000000000000000) : // -0
            bytes8 (0x0000000000000000); // 0
      else if (exponent < 15361) {
        significand = (significand | 0x10000000000000000000000000000) >> 15421 - exponent;
        exponent = 0;
      } else {
        significand >>= 60;
        exponent -= 15360;
      }

      uint64 result = uint64 (significand | exponent << 52);
      if (negative) result |= 0x8000000000000000;

      return bytes8 (result);
    }
  }

  /**
   * Test whether given quadruple precision number is NaN.
   *
   * @param x quadruple precision number
   * @return true if x is NaN, false otherwise
   */
  function isNaN (bytes16 x) internal pure returns (bool) {
    unchecked {
      return uint128 (x) & 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF >
        0x7FFF0000000000000000000000000000;
    }
  }

  /**
   * Test whether given quadruple precision number is positive or negative
   * infinity.
   *
   * @param x quadruple precision number
   * @return true if x is positive or negative infinity, false otherwise
   */
  function isInfinity (bytes16 x) internal pure returns (bool) {
    unchecked {
      return uint128 (x) & 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF ==
        0x7FFF0000000000000000000000000000;
    }
  }

  /**
   * Calculate sign of x, i.e. -1 if x is negative, 0 if x if zero, and 1 if x
   * is positive.  Note that sign (-0) is zero.  Revert if x is NaN. 
   *
   * @param x quadruple precision number
   * @return sign of x
   */
  function sign (bytes16 x) internal pure returns (int8) {
    unchecked {
      uint128 absoluteX = uint128 (x) & 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

      require (absoluteX <= 0x7FFF0000000000000000000000000000); // Not NaN

      if (absoluteX == 0) return 0;
      else if (uint128 (x) >= 0x80000000000000000000000000000000) return -1;
      else return 1;
    }
  }

  /**
   * Calculate sign (x - y).  Revert if either argument is NaN, or both
   * arguments are infinities of the same sign. 
   *
   * @param x quadruple precision number
   * @param y quadruple precision number
   * @return sign (x - y)
   */
  function cmp (bytes16 x, bytes16 y) internal pure returns (int8) {
    unchecked {
      uint128 absoluteX = uint128 (x) & 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

      require (absoluteX <= 0x7FFF0000000000000000000000000000); // Not NaN

      uint128 absoluteY = uint128 (y) & 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

      require (absoluteY <= 0x7FFF0000000000000000000000000000); // Not NaN

      // Not infinities of the same sign
      require (x != y || absoluteX < 0x7FFF0000000000000000000000000000);

      if (x == y) return 0;
      else {
        bool negativeX = uint128 (x) >= 0x80000000000000000000000000000000;
        bool negativeY = uint128 (y) >= 0x80000000000000000000000000000000;

        if (negativeX) {
          if (negativeY) return absoluteX > absoluteY ? -1 : int8 (1);
          else return -1; 
        } else {
          if (negativeY) return 1;
          else return absoluteX > absoluteY ? int8 (1) : -1;
        }
      }
    }
  }

  /**
   * Test whether x equals y.  NaN, infinity, and -infinity are not equal to
   * anything. 
   *
   * @param x quadruple precision number
   * @param y quadruple precision number
   * @return true if x equals to y, false otherwise
   */
  function eq (bytes16 x, bytes16 y) internal pure returns (bool) {
    unchecked {
      if (x == y) {
        return uint128 (x) & 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF <
          0x7FFF0000000000000000000000000000;
      } else return false;
    }
  }

  /**
   * Calculate x + y.  Special values behave in the following way:
   *
   * NaN + x = NaN for any x.
   * Infinity + x = Infinity for any finite x.
   * -Infinity + x = -Infinity for any finite x.
   * Infinity + Infinity = Infinity.
   * -Infinity + -Infinity = -Infinity.
   * Infinity + -Infinity = -Infinity + Infinity = NaN.
   *
   * @param x quadruple precision number
   * @param y quadruple precision number
   * @return quadruple precision number
   */
  function add (bytes16 x, bytes16 y) internal pure returns (bytes16) {
    unchecked {
      uint256 xExponent = uint128 (x) >> 112 & 0x7FFF;
      uint256 yExponent = uint128 (y) >> 112 & 0x7FFF;

      if (xExponent == 0x7FFF) {
        if (yExponent == 0x7FFF) { 
          if (x == y) return x;
          else return NaN;
        } else return x; 
      } else if (yExponent == 0x7FFF) return y;
      else {
        bool xSign = uint128 (x) >= 0x80000000000000000000000000000000;
        uint256 xSignifier = uint128 (x) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
        if (xExponent == 0) xExponent = 1;
        else xSignifier |= 0x10000000000000000000000000000;

        bool ySign = uint128 (y) >= 0x80000000000000000000000000000000;
        uint256 ySignifier = uint128 (y) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
        if (yExponent == 0) yExponent = 1;
        else ySignifier |= 0x10000000000000000000000000000;

        if (xSignifier == 0) return y == NEGATIVE_ZERO ? POSITIVE_ZERO : y;
        else if (ySignifier == 0) return x == NEGATIVE_ZERO ? POSITIVE_ZERO : x;
        else {
          int256 delta = int256 (xExponent) - int256 (yExponent);
  
          if (xSign == ySign) {
            if (delta > 112) return x;
            else if (delta > 0) ySignifier >>= uint256 (delta);
            else if (delta < -112) return y;
            else if (delta < 0) {
              xSignifier >>= uint256 (-delta);
              xExponent = yExponent;
            }
  
            xSignifier += ySignifier;
  
            if (xSignifier >= 0x20000000000000000000000000000) {
              xSignifier >>= 1;
              xExponent += 1;
            }
  
            if (xExponent == 0x7FFF)
              return xSign ? NEGATIVE_INFINITY : POSITIVE_INFINITY;
            else {
              if (xSignifier < 0x10000000000000000000000000000) xExponent = 0;
              else xSignifier &= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
  
              return bytes16 (uint128 (
                  (xSign ? 0x80000000000000000000000000000000 : 0) |
                  (xExponent << 112) |
                  xSignifier)); 
            }
          } else {
            if (delta > 0) {
              xSignifier <<= 1;
              xExponent -= 1;
            } else if (delta < 0) {
              ySignifier <<= 1;
              xExponent = yExponent - 1;
            }

            if (delta > 112) ySignifier = 1;
            else if (delta > 1) ySignifier = (ySignifier - 1 >> uint256 (delta - 1)) + 1;
            else if (delta < -112) xSignifier = 1;
            else if (delta < -1) xSignifier = (xSignifier - 1 >> uint256 (-delta - 1)) + 1;

            if (xSignifier >= ySignifier) xSignifier -= ySignifier;
            else {
              xSignifier = ySignifier - xSignifier;
              xSign = ySign;
            }

            if (xSignifier == 0)
              return POSITIVE_ZERO;

            uint256 msb = mostSignificantBit (xSignifier);

            if (msb == 113) {
              xSignifier = xSignifier >> 1 & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
              xExponent += 1;
            } else if (msb < 112) {
              uint256 shift = 112 - msb;
              if (xExponent > shift) {
                xSignifier = xSignifier << shift & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
                xExponent -= shift;
              } else {
                xSignifier <<= xExponent - 1;
                xExponent = 0;
              }
            } else xSignifier &= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

            if (xExponent == 0x7FFF)
              return xSign ? NEGATIVE_INFINITY : POSITIVE_INFINITY;
            else return bytes16 (uint128 (
                (xSign ? 0x80000000000000000000000000000000 : 0) |
                (xExponent << 112) |
                xSignifier));
          }
        }
      }
    }
  }

  /**
   * Calculate x - y.  Special values behave in the following way:
   *
   * NaN - x = NaN for any x.
   * Infinity - x = Infinity for any finite x.
   * -Infinity - x = -Infinity for any finite x.
   * Infinity - -Infinity = Infinity.
   * -Infinity - Infinity = -Infinity.
   * Infinity - Infinity = -Infinity - -Infinity = NaN.
   *
   * @param x quadruple precision number
   * @param y quadruple precision number
   * @return quadruple precision number
   */
  function sub (bytes16 x, bytes16 y) internal pure returns (bytes16) {
    unchecked {
      return add (x, y ^ 0x80000000000000000000000000000000);
    }
  }

  /**
   * Calculate x * y.  Special values behave in the following way:
   *
   * NaN * x = NaN for any x.
   * Infinity * x = Infinity for any finite positive x.
   * Infinity * x = -Infinity for any finite negative x.
   * -Infinity * x = -Infinity for any finite positive x.
   * -Infinity * x = Infinity for any finite negative x.
   * Infinity * 0 = NaN.
   * -Infinity * 0 = NaN.
   * Infinity * Infinity = Infinity.
   * Infinity * -Infinity = -Infinity.
   * -Infinity * Infinity = -Infinity.
   * -Infinity * -Infinity = Infinity.
   *
   * @param x quadruple precision number
   * @param y quadruple precision number
   * @return quadruple precision number
   */
  function mul (bytes16 x, bytes16 y) internal pure returns (bytes16) {
    unchecked {
      uint256 xExponent = uint128 (x) >> 112 & 0x7FFF;
      uint256 yExponent = uint128 (y) >> 112 & 0x7FFF;

      if (xExponent == 0x7FFF) {
        if (yExponent == 0x7FFF) {
          if (x == y) return x ^ y & 0x80000000000000000000000000000000;
          else if (x ^ y == 0x80000000000000000000000000000000) return x | y;
          else return NaN;
        } else {
          if (y & 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF == 0) return NaN;
          else return x ^ y & 0x80000000000000000000000000000000;
        }
      } else if (yExponent == 0x7FFF) {
          if (x & 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF == 0) return NaN;
          else return y ^ x & 0x80000000000000000000000000000000;
      } else {
        uint256 xSignifier = uint128 (x) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
        if (xExponent == 0) xExponent = 1;
        else xSignifier |= 0x10000000000000000000000000000;

        uint256 ySignifier = uint128 (y) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
        if (yExponent == 0) yExponent = 1;
        else ySignifier |= 0x10000000000000000000000000000;

        xSignifier *= ySignifier;
        if (xSignifier == 0)
          return (x ^ y) & 0x80000000000000000000000000000000 > 0 ?
              NEGATIVE_ZERO : POSITIVE_ZERO;

        xExponent += yExponent;

        uint256 msb =
          xSignifier >= 0x200000000000000000000000000000000000000000000000000000000 ? 225 :
          xSignifier >= 0x100000000000000000000000000000000000000000000000000000000 ? 224 :
          mostSignificantBit (xSignifier);

        if (xExponent + msb < 16496) { // Underflow
          xExponent = 0;
          xSignifier = 0;
        } else if (xExponent + msb < 16608) { // Subnormal
          if (xExponent < 16496)
            xSignifier >>= 16496 - xExponent;
          else if (xExponent > 16496)
            xSignifier <<= xExponent - 16496;
          xExponent = 0;
        } else if (xExponent + msb > 49373) {
          xExponent = 0x7FFF;
          xSignifier = 0;
        } else {
          if (msb > 112)
            xSignifier >>= msb - 112;
          else if (msb < 112)
            xSignifier <<= 112 - msb;

          xSignifier &= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

          xExponent = xExponent + msb - 16607;
        }

        return bytes16 (uint128 (uint128 ((x ^ y) & 0x80000000000000000000000000000000) |
            xExponent << 112 | xSignifier));
      }
    }
  }

  /**
   * Calculate x / y.  Special values behave in the following way:
   *
   * NaN / x = NaN for any x.
   * x / NaN = NaN for any x.
   * Infinity / x = Infinity for any finite non-negative x.
   * Infinity / x = -Infinity for any finite negative x including -0.
   * -Infinity / x = -Infinity for any finite non-negative x.
   * -Infinity / x = Infinity for any finite negative x including -0.
   * x / Infinity = 0 for any finite non-negative x.
   * x / -Infinity = -0 for any finite non-negative x.
   * x / Infinity = -0 for any finite non-negative x including -0.
   * x / -Infinity = 0 for any finite non-negative x including -0.
   * 
   * Infinity / Infinity = NaN.
   * Infinity / -Infinity = -NaN.
   * -Infinity / Infinity = -NaN.
   * -Infinity / -Infinity = NaN.
   *
   * Division by zero behaves in the following way:
   *
   * x / 0 = Infinity for any finite positive x.
   * x / -0 = -Infinity for any finite positive x.
   * x / 0 = -Infinity for any finite negative x.
   * x / -0 = Infinity for any finite negative x.
   * 0 / 0 = NaN.
   * 0 / -0 = NaN.
   * -0 / 0 = NaN.
   * -0 / -0 = NaN.
   *
   * @param x quadruple precision number
   * @param y quadruple precision number
   * @return quadruple precision number
   */
  function div (bytes16 x, bytes16 y) internal pure returns (bytes16) {
    unchecked {
      uint256 xExponent = uint128 (x) >> 112 & 0x7FFF;
      uint256 yExponent = uint128 (y) >> 112 & 0x7FFF;

      if (xExponent == 0x7FFF) {
        if (yExponent == 0x7FFF) return NaN;
        else return x ^ y & 0x80000000000000000000000000000000;
      } else if (yExponent == 0x7FFF) {
        if (y & 0x0000FFFFFFFFFFFFFFFFFFFFFFFFFFFF != 0) return NaN;
        else return POSITIVE_ZERO | (x ^ y) & 0x80000000000000000000000000000000;
      } else if (y & 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF == 0) {
        if (x & 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF == 0) return NaN;
        else return POSITIVE_INFINITY | (x ^ y) & 0x80000000000000000000000000000000;
      } else {
        uint256 ySignifier = uint128 (y) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
        if (yExponent == 0) yExponent = 1;
        else ySignifier |= 0x10000000000000000000000000000;

        uint256 xSignifier = uint128 (x) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
        if (xExponent == 0) {
          if (xSignifier != 0) {
            uint shift = 226 - mostSignificantBit (xSignifier);

            xSignifier <<= shift;

            xExponent = 1;
            yExponent += shift - 114;
          }
        }
        else {
          xSignifier = (xSignifier | 0x10000000000000000000000000000) << 114;
        }

        xSignifier = xSignifier / ySignifier;
        if (xSignifier == 0)
          return (x ^ y) & 0x80000000000000000000000000000000 > 0 ?
              NEGATIVE_ZERO : POSITIVE_ZERO;

        assert (xSignifier >= 0x1000000000000000000000000000);

        uint256 msb =
          xSignifier >= 0x80000000000000000000000000000 ? mostSignificantBit (xSignifier) :
          xSignifier >= 0x40000000000000000000000000000 ? 114 :
          xSignifier >= 0x20000000000000000000000000000 ? 113 : 112;

        if (xExponent + msb > yExponent + 16497) { // Overflow
          xExponent = 0x7FFF;
          xSignifier = 0;
        } else if (xExponent + msb + 16380  < yExponent) { // Underflow
          xExponent = 0;
          xSignifier = 0;
        } else if (xExponent + msb + 16268  < yExponent) { // Subnormal
          if (xExponent + 16380 > yExponent)
            xSignifier <<= xExponent + 16380 - yExponent;
          else if (xExponent + 16380 < yExponent)
            xSignifier >>= yExponent - xExponent - 16380;

          xExponent = 0;
        } else { // Normal
          if (msb > 112)
            xSignifier >>= msb - 112;

          xSignifier &= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

          xExponent = xExponent + msb + 16269 - yExponent;
        }

        return bytes16 (uint128 (uint128 ((x ^ y) & 0x80000000000000000000000000000000) |
            xExponent << 112 | xSignifier));
      }
    }
  }

  /**
   * Calculate -x.
   *
   * @param x quadruple precision number
   * @return quadruple precision number
   */
  function neg (bytes16 x) internal pure returns (bytes16) {
    unchecked {
      return x ^ 0x80000000000000000000000000000000;
    }
  }

  /**
   * Calculate |x|.
   *
   * @param x quadruple precision number
   * @return quadruple precision number
   */
  function abs (bytes16 x) internal pure returns (bytes16) {
    unchecked {
      return x & 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
    }
  }

  /**
   * Calculate square root of x.  Return NaN on negative x excluding -0.
   *
   * @param x quadruple precision number
   * @return quadruple precision number
   */
  function sqrt (bytes16 x) internal pure returns (bytes16) {
    unchecked {
      if (uint128 (x) >  0x80000000000000000000000000000000) return NaN;
      else {
        uint256 xExponent = uint128 (x) >> 112 & 0x7FFF;
        if (xExponent == 0x7FFF) return x;
        else {
          uint256 xSignifier = uint128 (x) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
          if (xExponent == 0) xExponent = 1;
          else xSignifier |= 0x10000000000000000000000000000;

          if (xSignifier == 0) return POSITIVE_ZERO;

          bool oddExponent = xExponent & 0x1 == 0;
          xExponent = xExponent + 16383 >> 1;

          if (oddExponent) {
            if (xSignifier >= 0x10000000000000000000000000000)
              xSignifier <<= 113;
            else {
              uint256 msb = mostSignificantBit (xSignifier);
              uint256 shift = (226 - msb) & 0xFE;
              xSignifier <<= shift;
              xExponent -= shift - 112 >> 1;
            }
          } else {
            if (xSignifier >= 0x10000000000000000000000000000)
              xSignifier <<= 112;
            else {
              uint256 msb = mostSignificantBit (xSignifier);
              uint256 shift = (225 - msb) & 0xFE;
              xSignifier <<= shift;
              xExponent -= shift - 112 >> 1;
            }
          }

          uint256 r = 0x10000000000000000000000000000;
          r = (r + xSignifier / r) >> 1;
          r = (r + xSignifier / r) >> 1;
          r = (r + xSignifier / r) >> 1;
          r = (r + xSignifier / r) >> 1;
          r = (r + xSignifier / r) >> 1;
          r = (r + xSignifier / r) >> 1;
          r = (r + xSignifier / r) >> 1; // Seven iterations should be enough
          uint256 r1 = xSignifier / r;
          if (r1 < r) r = r1;

          return bytes16 (uint128 (xExponent << 112 | r & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF));
        }
      }
    }
  }

  /**
   * Calculate binary logarithm of x.  Return NaN on negative x excluding -0.
   *
   * @param x quadruple precision number
   * @return quadruple precision number
   */
  function log_2 (bytes16 x) internal pure returns (bytes16) {
    unchecked {
      if (uint128 (x) > 0x80000000000000000000000000000000) return NaN;
      else if (x == 0x3FFF0000000000000000000000000000) return POSITIVE_ZERO; 
      else {
        uint256 xExponent = uint128 (x) >> 112 & 0x7FFF;
        if (xExponent == 0x7FFF) return x;
        else {
          uint256 xSignifier = uint128 (x) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
          if (xExponent == 0) xExponent = 1;
          else xSignifier |= 0x10000000000000000000000000000;

          if (xSignifier == 0) return NEGATIVE_INFINITY;

          bool resultNegative;
          uint256 resultExponent = 16495;
          uint256 resultSignifier;

          if (xExponent >= 0x3FFF) {
            resultNegative = false;
            resultSignifier = xExponent - 0x3FFF;
            xSignifier <<= 15;
          } else {
            resultNegative = true;
            if (xSignifier >= 0x10000000000000000000000000000) {
              resultSignifier = 0x3FFE - xExponent;
              xSignifier <<= 15;
            } else {
              uint256 msb = mostSignificantBit (xSignifier);
              resultSignifier = 16493 - msb;
              xSignifier <<= 127 - msb;
            }
          }

          if (xSignifier == 0x80000000000000000000000000000000) {
            if (resultNegative) resultSignifier += 1;
            uint256 shift = 112 - mostSignificantBit (resultSignifier);
            resultSignifier <<= shift;
            resultExponent -= shift;
          } else {
            uint256 bb = resultNegative ? 1 : 0;
            while (resultSignifier < 0x10000000000000000000000000000) {
              resultSignifier <<= 1;
              resultExponent -= 1;
  
              xSignifier *= xSignifier;
              uint256 b = xSignifier >> 255;
              resultSignifier += b ^ bb;
              xSignifier >>= 127 + b;
            }
          }

          return bytes16 (uint128 ((resultNegative ? 0x80000000000000000000000000000000 : 0) |
              resultExponent << 112 | resultSignifier & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF));
        }
      }
    }
  }

  /**
   * Calculate natural logarithm of x.  Return NaN on negative x excluding -0.
   *
   * @param x quadruple precision number
   * @return quadruple precision number
   */
  function ln (bytes16 x) internal pure returns (bytes16) {
    unchecked {
      return mul (log_2 (x), 0x3FFE62E42FEFA39EF35793C7673007E5);
    }
  }

  /**
   * Calculate 2^x.
   *
   * @param x quadruple precision number
   * @return quadruple precision number
   */
  function pow_2 (bytes16 x) internal pure returns (bytes16) {
    unchecked {
      bool xNegative = uint128 (x) > 0x80000000000000000000000000000000;
      uint256 xExponent = uint128 (x) >> 112 & 0x7FFF;
      uint256 xSignifier = uint128 (x) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

      if (xExponent == 0x7FFF && xSignifier != 0) return NaN;
      else if (xExponent > 16397)
        return xNegative ? POSITIVE_ZERO : POSITIVE_INFINITY;
      else if (xExponent < 16255)
        return 0x3FFF0000000000000000000000000000;
      else {
        if (xExponent == 0) xExponent = 1;
        else xSignifier |= 0x10000000000000000000000000000;

        if (xExponent > 16367)
          xSignifier <<= xExponent - 16367;
        else if (xExponent < 16367)
          xSignifier >>= 16367 - xExponent;

        if (xNegative && xSignifier > 0x406E00000000000000000000000000000000)
          return POSITIVE_ZERO;

        if (!xNegative && xSignifier > 0x3FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
          return POSITIVE_INFINITY;

        uint256 resultExponent = xSignifier >> 128;
        xSignifier &= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
        if (xNegative && xSignifier != 0) {
          xSignifier = ~xSignifier;
          resultExponent += 1;
        }

        uint256 resultSignifier = 0x80000000000000000000000000000000;
        if (xSignifier & 0x80000000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x16A09E667F3BCC908B2FB1366EA957D3E >> 128;
        if (xSignifier & 0x40000000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x1306FE0A31B7152DE8D5A46305C85EDEC >> 128;
        if (xSignifier & 0x20000000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x1172B83C7D517ADCDF7C8C50EB14A791F >> 128;
        if (xSignifier & 0x10000000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x10B5586CF9890F6298B92B71842A98363 >> 128;
        if (xSignifier & 0x8000000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x1059B0D31585743AE7C548EB68CA417FD >> 128;
        if (xSignifier & 0x4000000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x102C9A3E778060EE6F7CACA4F7A29BDE8 >> 128;
        if (xSignifier & 0x2000000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x10163DA9FB33356D84A66AE336DCDFA3F >> 128;
        if (xSignifier & 0x1000000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x100B1AFA5ABCBED6129AB13EC11DC9543 >> 128;
        if (xSignifier & 0x800000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x10058C86DA1C09EA1FF19D294CF2F679B >> 128;
        if (xSignifier & 0x400000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x1002C605E2E8CEC506D21BFC89A23A00F >> 128;
        if (xSignifier & 0x200000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x100162F3904051FA128BCA9C55C31E5DF >> 128;
        if (xSignifier & 0x100000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x1000B175EFFDC76BA38E31671CA939725 >> 128;
        if (xSignifier & 0x80000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x100058BA01FB9F96D6CACD4B180917C3D >> 128;
        if (xSignifier & 0x40000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x10002C5CC37DA9491D0985C348C68E7B3 >> 128;
        if (xSignifier & 0x20000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x1000162E525EE054754457D5995292026 >> 128;
        if (xSignifier & 0x10000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x10000B17255775C040618BF4A4ADE83FC >> 128;
        if (xSignifier & 0x8000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x1000058B91B5BC9AE2EED81E9B7D4CFAB >> 128;
        if (xSignifier & 0x4000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x100002C5C89D5EC6CA4D7C8ACC017B7C9 >> 128;
        if (xSignifier & 0x2000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x10000162E43F4F831060E02D839A9D16D >> 128;
        if (xSignifier & 0x1000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x100000B1721BCFC99D9F890EA06911763 >> 128;
        if (xSignifier & 0x800000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x10000058B90CF1E6D97F9CA14DBCC1628 >> 128;
        if (xSignifier & 0x400000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x1000002C5C863B73F016468F6BAC5CA2B >> 128;
        if (xSignifier & 0x200000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x100000162E430E5A18F6119E3C02282A5 >> 128;
        if (xSignifier & 0x100000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x1000000B1721835514B86E6D96EFD1BFE >> 128;
        if (xSignifier & 0x80000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x100000058B90C0B48C6BE5DF846C5B2EF >> 128;
        if (xSignifier & 0x40000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x10000002C5C8601CC6B9E94213C72737A >> 128;
        if (xSignifier & 0x20000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x1000000162E42FFF037DF38AA2B219F06 >> 128;
        if (xSignifier & 0x10000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x10000000B17217FBA9C739AA5819F44F9 >> 128;
        if (xSignifier & 0x8000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x1000000058B90BFCDEE5ACD3C1CEDC823 >> 128;
        if (xSignifier & 0x4000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x100000002C5C85FE31F35A6A30DA1BE50 >> 128;
        if (xSignifier & 0x2000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x10000000162E42FF0999CE3541B9FFFCF >> 128;
        if (xSignifier & 0x1000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x100000000B17217F80F4EF5AADDA45554 >> 128;
        if (xSignifier & 0x800000000000000000000000 > 0) resultSignifier = resultSignifier * 0x10000000058B90BFBF8479BD5A81B51AD >> 128;
        if (xSignifier & 0x400000000000000000000000 > 0) resultSignifier = resultSignifier * 0x1000000002C5C85FDF84BD62AE30A74CC >> 128;
        if (xSignifier & 0x200000000000000000000000 > 0) resultSignifier = resultSignifier * 0x100000000162E42FEFB2FED257559BDAA >> 128;
        if (xSignifier & 0x100000000000000000000000 > 0) resultSignifier = resultSignifier * 0x1000000000B17217F7D5A7716BBA4A9AE >> 128;
        if (xSignifier & 0x80000000000000000000000 > 0) resultSignifier = resultSignifier * 0x100000000058B90BFBE9DDBAC5E109CCE >> 128;
        if (xSignifier & 0x40000000000000000000000 > 0) resultSignifier = resultSignifier * 0x10000000002C5C85FDF4B15DE6F17EB0D >> 128;
        if (xSignifier & 0x20000000000000000000000 > 0) resultSignifier = resultSignifier * 0x1000000000162E42FEFA494F1478FDE05 >> 128;
        if (xSignifier & 0x10000000000000000000000 > 0) resultSignifier = resultSignifier * 0x10000000000B17217F7D20CF927C8E94C >> 128;
        if (xSignifier & 0x8000000000000000000000 > 0) resultSignifier = resultSignifier * 0x1000000000058B90BFBE8F71CB4E4B33D >> 128;
        if (xSignifier & 0x4000000000000000000000 > 0) resultSignifier = resultSignifier * 0x100000000002C5C85FDF477B662B26945 >> 128;
        if (xSignifier & 0x2000000000000000000000 > 0) resultSignifier = resultSignifier * 0x10000000000162E42FEFA3AE53369388C >> 128;
        if (xSignifier & 0x1000000000000000000000 > 0) resultSignifier = resultSignifier * 0x100000000000B17217F7D1D351A389D40 >> 128;
        if (xSignifier & 0x800000000000000000000 > 0) resultSignifier = resultSignifier * 0x10000000000058B90BFBE8E8B2D3D4EDE >> 128;
        if (xSignifier & 0x400000000000000000000 > 0) resultSignifier = resultSignifier * 0x1000000000002C5C85FDF4741BEA6E77E >> 128;
        if (xSignifier & 0x200000000000000000000 > 0) resultSignifier = resultSignifier * 0x100000000000162E42FEFA39FE95583C2 >> 128;
        if (xSignifier & 0x100000000000000000000 > 0) resultSignifier = resultSignifier * 0x1000000000000B17217F7D1CFB72B45E1 >> 128;
        if (xSignifier & 0x80000000000000000000 > 0) resultSignifier = resultSignifier * 0x100000000000058B90BFBE8E7CC35C3F0 >> 128;
        if (xSignifier & 0x40000000000000000000 > 0) resultSignifier = resultSignifier * 0x10000000000002C5C85FDF473E242EA38 >> 128;
        if (xSignifier & 0x20000000000000000000 > 0) resultSignifier = resultSignifier * 0x1000000000000162E42FEFA39F02B772C >> 128;
        if (xSignifier & 0x10000000000000000000 > 0) resultSignifier = resultSignifier * 0x10000000000000B17217F7D1CF7D83C1A >> 128;
        if (xSignifier & 0x8000000000000000000 > 0) resultSignifier = resultSignifier * 0x1000000000000058B90BFBE8E7BDCBE2E >> 128;
        if (xSignifier & 0x4000000000000000000 > 0) resultSignifier = resultSignifier * 0x100000000000002C5C85FDF473DEA871F >> 128;
        if (xSignifier & 0x2000000000000000000 > 0) resultSignifier = resultSignifier * 0x10000000000000162E42FEFA39EF44D91 >> 128;
        if (xSignifier & 0x1000000000000000000 > 0) resultSignifier = resultSignifier * 0x100000000000000B17217F7D1CF79E949 >> 128;
        if (xSignifier & 0x800000000000000000 > 0) resultSignifier = resultSignifier * 0x10000000000000058B90BFBE8E7BCE544 >> 128;
        if (xSignifier & 0x400000000000000000 > 0) resultSignifier = resultSignifier * 0x1000000000000002C5C85FDF473DE6ECA >> 128;
        if (xSignifier & 0x200000000000000000 > 0) resultSignifier = resultSignifier * 0x100000000000000162E42FEFA39EF366F >> 128;
        if (xSignifier & 0x100000000000000000 > 0) resultSignifier = resultSignifier * 0x1000000000000000B17217F7D1CF79AFA >> 128;
        if (xSignifier & 0x80000000000000000 > 0) resultSignifier = resultSignifier * 0x100000000000000058B90BFBE8E7BCD6D >> 128;
        if (xSignifier & 0x40000000000000000 > 0) resultSignifier = resultSignifier * 0x10000000000000002C5C85FDF473DE6B2 >> 128;
        if (xSignifier & 0x20000000000000000 > 0) resultSignifier = resultSignifier * 0x1000000000000000162E42FEFA39EF358 >> 128;
        if (xSignifier & 0x10000000000000000 > 0) resultSignifier = resultSignifier * 0x10000000000000000B17217F7D1CF79AB >> 128;
        if (xSignifier & 0x8000000000000000 > 0) resultSignifier = resultSignifier * 0x1000000000000000058B90BFBE8E7BCD5 >> 128;
        if (xSignifier & 0x4000000000000000 > 0) resultSignifier = resultSignifier * 0x100000000000000002C5C85FDF473DE6A >> 128;
        if (xSignifier & 0x2000000000000000 > 0) resultSignifier = resultSignifier * 0x10000000000000000162E42FEFA39EF34 >> 128;
        if (xSignifier & 0x1000000000000000 > 0) resultSignifier = resultSignifier * 0x100000000000000000B17217F7D1CF799 >> 128;
        if (xSignifier & 0x800000000000000 > 0) resultSignifier = resultSignifier * 0x10000000000000000058B90BFBE8E7BCC >> 128;
        if (xSignifier & 0x400000000000000 > 0) resultSignifier = resultSignifier * 0x1000000000000000002C5C85FDF473DE5 >> 128;
        if (xSignifier & 0x200000000000000 > 0) resultSignifier = resultSignifier * 0x100000000000000000162E42FEFA39EF2 >> 128;
        if (xSignifier & 0x100000000000000 > 0) resultSignifier = resultSignifier * 0x1000000000000000000B17217F7D1CF78 >> 128;
        if (xSignifier & 0x80000000000000 > 0) resultSignifier = resultSignifier * 0x100000000000000000058B90BFBE8E7BB >> 128;
        if (xSignifier & 0x40000000000000 > 0) resultSignifier = resultSignifier * 0x10000000000000000002C5C85FDF473DD >> 128;
        if (xSignifier & 0x20000000000000 > 0) resultSignifier = resultSignifier * 0x1000000000000000000162E42FEFA39EE >> 128;
        if (xSignifier & 0x10000000000000 > 0) resultSignifier = resultSignifier * 0x10000000000000000000B17217F7D1CF6 >> 128;
        if (xSignifier & 0x8000000000000 > 0) resultSignifier = resultSignifier * 0x1000000000000000000058B90BFBE8E7A >> 128;
        if (xSignifier & 0x4000000000000 > 0) resultSignifier = resultSignifier * 0x100000000000000000002C5C85FDF473C >> 128;
        if (xSignifier & 0x2000000000000 > 0) resultSignifier = resultSignifier * 0x10000000000000000000162E42FEFA39D >> 128;
        if (xSignifier & 0x1000000000000 > 0) resultSignifier = resultSignifier * 0x100000000000000000000B17217F7D1CE >> 128;
        if (xSignifier & 0x800000000000 > 0) resultSignifier = resultSignifier * 0x10000000000000000000058B90BFBE8E6 >> 128;
        if (xSignifier & 0x400000000000 > 0) resultSignifier = resultSignifier * 0x1000000000000000000002C5C85FDF472 >> 128;
        if (xSignifier & 0x200000000000 > 0) resultSignifier = resultSignifier * 0x100000000000000000000162E42FEFA38 >> 128;
        if (xSignifier & 0x100000000000 > 0) resultSignifier = resultSignifier * 0x1000000000000000000000B17217F7D1B >> 128;
        if (xSignifier & 0x80000000000 > 0) resultSignifier = resultSignifier * 0x100000000000000000000058B90BFBE8D >> 128;
        if (xSignifier & 0x40000000000 > 0) resultSignifier = resultSignifier * 0x10000000000000000000002C5C85FDF46 >> 128;
        if (xSignifier & 0x20000000000 > 0) resultSignifier = resultSignifier * 0x1000000000000000000000162E42FEFA2 >> 128;
        if (xSignifier & 0x10000000000 > 0) resultSignifier = resultSignifier * 0x10000000000000000000000B17217F7D0 >> 128;
        if (xSignifier & 0x8000000000 > 0) resultSignifier = resultSignifier * 0x1000000000000000000000058B90BFBE7 >> 128;
        if (xSignifier & 0x4000000000 > 0) resultSignifier = resultSignifier * 0x100000000000000000000002C5C85FDF3 >> 128;
        if (xSignifier & 0x2000000000 > 0) resultSignifier = resultSignifier * 0x10000000000000000000000162E42FEF9 >> 128;
        if (xSignifier & 0x1000000000 > 0) resultSignifier = resultSignifier * 0x100000000000000000000000B17217F7C >> 128;
        if (xSignifier & 0x800000000 > 0) resultSignifier = resultSignifier * 0x10000000000000000000000058B90BFBD >> 128;
        if (xSignifier & 0x400000000 > 0) resultSignifier = resultSignifier * 0x1000000000000000000000002C5C85FDE >> 128;
        if (xSignifier & 0x200000000 > 0) resultSignifier = resultSignifier * 0x100000000000000000000000162E42FEE >> 128;
        if (xSignifier & 0x100000000 > 0) resultSignifier = resultSignifier * 0x1000000000000000000000000B17217F6 >> 128;
        if (xSignifier & 0x80000000 > 0) resultSignifier = resultSignifier * 0x100000000000000000000000058B90BFA >> 128;
        if (xSignifier & 0x40000000 > 0) resultSignifier = resultSignifier * 0x10000000000000000000000002C5C85FC >> 128;
        if (xSignifier & 0x20000000 > 0) resultSignifier = resultSignifier * 0x1000000000000000000000000162E42FD >> 128;
        if (xSignifier & 0x10000000 > 0) resultSignifier = resultSignifier * 0x10000000000000000000000000B17217E >> 128;
        if (xSignifier & 0x8000000 > 0) resultSignifier = resultSignifier * 0x1000000000000000000000000058B90BE >> 128;
        if (xSignifier & 0x4000000 > 0) resultSignifier = resultSignifier * 0x100000000000000000000000002C5C85E >> 128;
        if (xSignifier & 0x2000000 > 0) resultSignifier = resultSignifier * 0x10000000000000000000000000162E42E >> 128;
        if (xSignifier & 0x1000000 > 0) resultSignifier = resultSignifier * 0x100000000000000000000000000B17216 >> 128;
        if (xSignifier & 0x800000 > 0) resultSignifier = resultSignifier * 0x10000000000000000000000000058B90A >> 128;
        if (xSignifier & 0x400000 > 0) resultSignifier = resultSignifier * 0x1000000000000000000000000002C5C84 >> 128;
        if (xSignifier & 0x200000 > 0) resultSignifier = resultSignifier * 0x100000000000000000000000000162E41 >> 128;
        if (xSignifier & 0x100000 > 0) resultSignifier = resultSignifier * 0x1000000000000000000000000000B1720 >> 128;
        if (xSignifier & 0x80000 > 0) resultSignifier = resultSignifier * 0x100000000000000000000000000058B8F >> 128;
        if (xSignifier & 0x40000 > 0) resultSignifier = resultSignifier * 0x10000000000000000000000000002C5C7 >> 128;
        if (xSignifier & 0x20000 > 0) resultSignifier = resultSignifier * 0x1000000000000000000000000000162E3 >> 128;
        if (xSignifier & 0x10000 > 0) resultSignifier = resultSignifier * 0x10000000000000000000000000000B171 >> 128;
        if (xSignifier & 0x8000 > 0) resultSignifier = resultSignifier * 0x1000000000000000000000000000058B8 >> 128;
        if (xSignifier & 0x4000 > 0) resultSignifier = resultSignifier * 0x100000000000000000000000000002C5B >> 128;
        if (xSignifier & 0x2000 > 0) resultSignifier = resultSignifier * 0x10000000000000000000000000000162D >> 128;
        if (xSignifier & 0x1000 > 0) resultSignifier = resultSignifier * 0x100000000000000000000000000000B16 >> 128;
        if (xSignifier & 0x800 > 0) resultSignifier = resultSignifier * 0x10000000000000000000000000000058A >> 128;
        if (xSignifier & 0x400 > 0) resultSignifier = resultSignifier * 0x1000000000000000000000000000002C4 >> 128;
        if (xSignifier & 0x200 > 0) resultSignifier = resultSignifier * 0x100000000000000000000000000000161 >> 128;
        if (xSignifier & 0x100 > 0) resultSignifier = resultSignifier * 0x1000000000000000000000000000000B0 >> 128;
        if (xSignifier & 0x80 > 0) resultSignifier = resultSignifier * 0x100000000000000000000000000000057 >> 128;
        if (xSignifier & 0x40 > 0) resultSignifier = resultSignifier * 0x10000000000000000000000000000002B >> 128;
        if (xSignifier & 0x20 > 0) resultSignifier = resultSignifier * 0x100000000000000000000000000000015 >> 128;
        if (xSignifier & 0x10 > 0) resultSignifier = resultSignifier * 0x10000000000000000000000000000000A >> 128;
        if (xSignifier & 0x8 > 0) resultSignifier = resultSignifier * 0x100000000000000000000000000000004 >> 128;
        if (xSignifier & 0x4 > 0) resultSignifier = resultSignifier * 0x100000000000000000000000000000001 >> 128;

        if (!xNegative) {
          resultSignifier = resultSignifier >> 15 & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
          resultExponent += 0x3FFF;
        } else if (resultExponent <= 0x3FFE) {
          resultSignifier = resultSignifier >> 15 & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
          resultExponent = 0x3FFF - resultExponent;
        } else {
          resultSignifier = resultSignifier >> resultExponent - 16367;
          resultExponent = 0;
        }

        return bytes16 (uint128 (resultExponent << 112 | resultSignifier));
      }
    }
  }

  /**
   * Calculate e^x.
   *
   * @param x quadruple precision number
   * @return quadruple precision number
   */
  function exp (bytes16 x) internal pure returns (bytes16) {
    unchecked {
      return pow_2 (mul (x, 0x3FFF71547652B82FE1777D0FFDA0D23A));
    }
  }

  /**
   * Get index of the most significant non-zero bit in binary representation of
   * x.  Reverts if x is zero.
   *
   * @return index of the most significant non-zero bit in binary representation
   *         of x
   */
  function mostSignificantBit (uint256 x) private pure returns (uint256) {
    unchecked {
      require (x > 0);

      uint256 result = 0;

      if (x >= 0x100000000000000000000000000000000) { x >>= 128; result += 128; }
      if (x >= 0x10000000000000000) { x >>= 64; result += 64; }
      if (x >= 0x100000000) { x >>= 32; result += 32; }
      if (x >= 0x10000) { x >>= 16; result += 16; }
      if (x >= 0x100) { x >>= 8; result += 8; }
      if (x >= 0x10) { x >>= 4; result += 4; }
      if (x >= 0x4) { x >>= 2; result += 2; }
      if (x >= 0x2) result += 1; // No need to shift x anymore

      return result;
    }
  }
}

library Constants {
    uint256 public constant MAX_VALUE = type(uint256).max;
    uint256 public constant WAD_LEVERAGE_1000 = 1_000e18;
    uint256 public constant YEAR_IN_SECONDS = 365 days;
    uint256 public constant MAX_CHUNK_SIZE = 50;
}

library InterestRates {
    using SafeCast for uint256;

    /// @notice Adds interest to given value using continuous compounding formula: v2 = value * e^(interestRate * time)
    /// @param value value to which interest is added, value represented in 18 decimals
    /// @param interestRatePeriodMultiplication interest rate * time, interest rate in 18 decimals, time in seconds
    /// @return value with interest, value represented in 18 decimals
    function addContinuousCompoundInterestUsingRatePeriodMultiplication(
        uint256 value,
        uint256 interestRatePeriodMultiplication
    ) internal pure returns (uint256) {
        uint256 interestRateYearsMultiplication = IporMath.division(
            interestRatePeriodMultiplication,
            Constants.YEAR_IN_SECONDS
        );
        bytes16 floatValue = _toQuadruplePrecision(value, 1e18);
        bytes16 floatIpm = _toQuadruplePrecision(interestRateYearsMultiplication, 1e18);
        bytes16 valueWithInterest = ABDKMathQuad.mul(floatValue, ABDKMathQuad.exp(floatIpm));
        return _toUint256(valueWithInterest);
    }

    /// @notice Adds interest to given value using continuous compounding formula: v2 = value * e^(interestRate * time)
    /// @param value value to which interest is added, value represented in 18 decimals
    /// @param interestRatePeriodMultiplication interest rate * time, interest rate in 18 decimals, time in seconds
    /// @return value with interest, value represented in 18 decimals
    function addContinuousCompoundInterestUsingRatePeriodMultiplicationInt(
        int256 value,
        int256 interestRatePeriodMultiplication
    ) internal pure returns (int256) {
        int256 interestRateYearsMultiplication = IporMath.divisionInt(
            interestRatePeriodMultiplication,
            Constants.YEAR_IN_SECONDS.toInt256()
        );
        bytes16 floatValue = _toQuadruplePrecisionInt(value, 1e18);
        bytes16 floatIpm = _toQuadruplePrecisionInt(interestRateYearsMultiplication, 1e18);
        bytes16 valueWithInterest = ABDKMathQuad.mul(floatValue, ABDKMathQuad.exp(floatIpm));
        return _toInt256(valueWithInterest);
    }

    /// @notice Calculates interest to given value using continuous compounding formula: v2 = value * e^(interestRate * time)
    /// @param value value to which interest is added, value represented in 18 decimals
    /// @param interestRatePeriodMultiplication interest rate * time, interest rate in 18 decimals, time in seconds
    /// @return interest, value represented in 18 decimals
    function calculateContinuousCompoundInterestUsingRatePeriodMultiplication(
        uint256 value,
        uint256 interestRatePeriodMultiplication
    ) internal pure returns (uint256) {
        return
            addContinuousCompoundInterestUsingRatePeriodMultiplication(value, interestRatePeriodMultiplication) - value;
    }

    /// @notice Calculates interest to given value using continuous compounding formula: v2 = value * e^(interestRate * time)
    /// @param value value to which interest is added, value represented in 18 decimals
    /// @param interestRatePeriodMultiplication interest rate * time, interest rate in 18 decimals, time in seconds
    /// @return interest, value represented in 18 decimals
    function calculateContinuousCompoundInterestUsingRatePeriodMultiplicationInt(
        int256 value,
        int256 interestRatePeriodMultiplication
    ) internal pure returns (int256) {
        return
            addContinuousCompoundInterestUsingRatePeriodMultiplicationInt(value, interestRatePeriodMultiplication) -
            value;
    }

    /// @dev Quadruple precision, 128 bits
    function _toQuadruplePrecision(uint256 number, uint256 decimals) private pure returns (bytes16) {
        if (number % decimals > 0) {
            /// @dev during calculation this value is lost in the conversion
            number += 1;
        }
        bytes16 nominator = ABDKMathQuad.fromUInt(number);
        bytes16 denominator = ABDKMathQuad.fromUInt(decimals);
        bytes16 fraction = ABDKMathQuad.div(nominator, denominator);
        return fraction;
    }

    /// @dev Quadruple precision, 128 bits
    function _toQuadruplePrecisionInt(int256 number, int256 decimals) private pure returns (bytes16) {
        if (number % decimals > 0) {
            /// @dev during calculation this value is lost in the conversion
            number += 1;
        }
        bytes16 nominator = ABDKMathQuad.fromInt(number);
        bytes16 denominator = ABDKMathQuad.fromInt(decimals);
        bytes16 fraction = ABDKMathQuad.div(nominator, denominator);
        return fraction;
    }

    function _toUint256(bytes16 value) private pure returns (uint256) {
        bytes16 decimals = ABDKMathQuad.fromUInt(1e18);
        bytes16 resultD18 = ABDKMathQuad.mul(value, decimals);
        return ABDKMathQuad.toUInt(resultD18);
    }

    function _toInt256(bytes16 value) private pure returns (int256) {
        bytes16 decimals = ABDKMathQuad.fromUInt(1e18);
        bytes16 resultD18 = ABDKMathQuad.mul(value, decimals);
        return ABDKMathQuad.toInt(resultD18);
    }
}

/// @title Core logic for IPOR Swap
library IporSwapLogic {
    using SafeCast for uint256;
    using SafeCast for int256;
    using InterestRates for uint256;
    using InterestRates for int256;

    /// @notice Calculates core amounts related with swap
    /// @param tenor swap duration, 0 = 28 days, 1 = 60 days, 2 = 90 days
    /// @param wadTotalAmount total amount represented in 18 decimals
    /// @param leverage swap leverage, represented in 18 decimals
    /// @param wadLiquidationDepositAmount liquidation deposit amount, represented in 18 decimals
    /// @param iporPublicationFeeAmount IPOR publication fee amount, represented in 18 decimals
    /// @param openingFeeRate opening fee rate, represented in 18 decimals
    /// @return collateral collateral amount, represented in 18 decimals
    /// @return notional notional amount, represented in 18 decimals
    /// @return openingFee opening fee amount, represented in 18 decimals
    /// @dev wadTotalAmount = collateral + openingFee + wadLiquidationDepositAmount + iporPublicationFeeAmount
    /// @dev Opening Fee is a multiplication openingFeeRate and notional
    function calculateSwapAmount(
        IporTypes.SwapTenor tenor,
        uint256 wadTotalAmount,
        uint256 leverage,
        uint256 wadLiquidationDepositAmount,
        uint256 iporPublicationFeeAmount,
        uint256 openingFeeRate
    ) internal pure returns (uint256 collateral, uint256 notional, uint256 openingFee) {
        require(
            wadTotalAmount > wadLiquidationDepositAmount + iporPublicationFeeAmount,
            AmmErrors.TOTAL_AMOUNT_LOWER_THAN_FEE
        );

        uint256 availableAmount = wadTotalAmount - wadLiquidationDepositAmount - iporPublicationFeeAmount;

        collateral = IporMath.division(
            availableAmount * 1e18,
            1e18 + IporMath.division(leverage * openingFeeRate * getTenorInDays(tenor), 365 * 1e18)
        );
        notional = IporMath.division(leverage * collateral, 1e18);
        openingFee = availableAmount - collateral;
    }

    /// @notice Calculates Profit and Loss (PnL) for a pay fixed swap for a given swap closing timestamp and IBT price from IporOracle.
    /// @param swap Swap structure
    /// @param closingTimestamp moment when swap is closed, represented in seconds
    /// @param mdIbtPrice IBT price from IporOracle, represented in 18 decimals
    /// @return pnlValue swap PnL, represented in 18 decimals
    /// @dev Calculated PnL not taken into consideration potential unwinding of the swap.
    function calculatePnlPayFixed(
        AmmTypes.Swap memory swap,
        uint256 closingTimestamp,
        uint256 mdIbtPrice
    ) internal pure returns (int256 pnlValue) {
        (uint256 interestFixed, uint256 interestFloating) = calculateInterest(swap, closingTimestamp, mdIbtPrice);

        pnlValue = normalizePnlValue(swap.collateral, interestFloating.toInt256() - interestFixed.toInt256());
    }

    /// @notice Calculates Profit and Loss (PnL) for a receive fixed swap for a given swap closing timestamp and IBT price from IporOracle.
    /// @param swap Swap structure
    /// @param closingTimestamp moment when swap is closed, represented in seconds
    /// @param mdIbtPrice IBT price from IporOracle, represented in 18 decimals
    /// @return pnlValue swap PnL, represented in 18 decimals
    /// @dev Calculated PnL not taken into consideration potential unwinding of the swap.
    function calculatePnlReceiveFixed(
        AmmTypes.Swap memory swap,
        uint256 closingTimestamp,
        uint256 mdIbtPrice
    ) internal pure returns (int256 pnlValue) {
        (uint256 interestFixed, uint256 interestFloating) = calculateInterest(swap, closingTimestamp, mdIbtPrice);

        pnlValue = normalizePnlValue(swap.collateral, interestFixed.toInt256() - interestFloating.toInt256());
    }

    /// @notice Calculates the swap unwind PnL value.
    /// @param swap Swap structure
    /// @param direction swap direction
    /// @param closingTimestamp moment when swap is closed, represented in seconds without 18 decimals
    /// for particular swap at time when swap will be closed by the trader.
    /// @dev Equation for this calculation is:
    /// time - number of seconds left to swap until maturity divided by number of seconds in year
    /// Opposite Leg Fixed Rate - calculated fixed rate of opposite leg used for the virtual swap
    /// @dev If Swap is Pay Fixed Receive Floating then UnwindValue  = Current Swap PnL + Notional * (e^(Opposite Leg Fixed Rate * time) - e^(Swap Fixed Rate * time))
    /// @dev If Swap is Receive Fixed Pay Floating then UnwindValue  = Current Swap PnL + Notional * (e^(Swap Fixed Rate * time) - e^(Opposite Leg Fixed Rate * time))
    function calculateSwapUnwindPnlValue(
        AmmTypes.Swap memory swap,
        AmmTypes.SwapDirection direction,
        uint256 closingTimestamp,
        uint256 oppositeLegFixedRate
    ) internal pure returns (int256 swapUnwindPnlValue) {
        uint256 endTimestamp = getSwapEndTimestamp(swap);

        require(closingTimestamp <= endTimestamp, AmmErrors.CANNOT_UNWIND_CLOSING_TOO_LATE);

        uint256 time = (endTimestamp - swap.openTimestamp) - (closingTimestamp - swap.openTimestamp);

        if (direction == AmmTypes.SwapDirection.PAY_FIXED_RECEIVE_FLOATING) {
            swapUnwindPnlValue =
                swap.notional.toInt256().calculateContinuousCompoundInterestUsingRatePeriodMultiplicationInt(
                    (oppositeLegFixedRate * time).toInt256()
                ) -
                swap.notional.toInt256().calculateContinuousCompoundInterestUsingRatePeriodMultiplicationInt(
                    (swap.fixedInterestRate * time).toInt256()
                );
        } else if (direction == AmmTypes.SwapDirection.PAY_FLOATING_RECEIVE_FIXED) {
            swapUnwindPnlValue =
                swap.notional.toInt256().calculateContinuousCompoundInterestUsingRatePeriodMultiplicationInt(
                    (swap.fixedInterestRate * time).toInt256()
                ) -
                swap.notional.toInt256().calculateContinuousCompoundInterestUsingRatePeriodMultiplicationInt(
                    (oppositeLegFixedRate * time).toInt256()
                );
        } else {
            revert(AmmErrors.UNSUPPORTED_DIRECTION);
        }
    }

    /// @notice Calculates the swap unwind opening fee amount for a given swap, closing timestamp and IBT price from IporOracle.
    /// @param swap Swap structure
    /// @param closingTimestamp moment when swap is closed, represented in seconds without 18 decimals
    /// @param openingFeeRateCfg opening fee rate taken from Protocol configuration, represented in 18 decimals
    /// @return swapOpeningFeeAmount swap opening fee amount, represented in 18 decimals
    function calculateSwapUnwindOpeningFeeAmount(
        AmmTypes.Swap memory swap,
        uint256 closingTimestamp,
        uint256 openingFeeRateCfg
    ) internal pure returns (uint256 swapOpeningFeeAmount) {
        require(closingTimestamp >= swap.openTimestamp, AmmErrors.CLOSING_TIMESTAMP_LOWER_THAN_SWAP_OPEN_TIMESTAMP);

        /// @dev 1e36 = 1e18 * 1e18, To achieve result in 18 decimals when there is multiplication of 3 numbers in 18 decimals, we need to divide by 1e36.
        swapOpeningFeeAmount = IporMath.division(
            swap.notional *
                openingFeeRateCfg *
                IporMath.division(
                    ((getSwapEndTimestamp(swap) - swap.openTimestamp) - (closingTimestamp - swap.openTimestamp)) * 1e18,
                    365 days
                ),
            1e36
        );
    }

    /// @notice Calculates interest including continuous capitalization for a given swap, closing timestamp and IBT price from IporOracle.
    /// @param swap Swap structure
    /// @param closingTimestamp moment when swap is closed, represented in seconds without 18 decimals
    /// @param mdIbtPrice IBT price from IporOracle, represented in 18 decimals
    /// @return interestFixed fixed interest chunk, represented in 18 decimals
    /// @return interestFloating floating interest chunk, represented in 18 decimals
    function calculateInterest(
        AmmTypes.Swap memory swap,
        uint256 closingTimestamp,
        uint256 mdIbtPrice
    ) internal pure returns (uint256 interestFixed, uint256 interestFloating) {
        require(closingTimestamp >= swap.openTimestamp, AmmErrors.CLOSING_TIMESTAMP_LOWER_THAN_SWAP_OPEN_TIMESTAMP);

        interestFixed = calculateInterestFixed(
            swap.notional,
            swap.fixedInterestRate,
            closingTimestamp - swap.openTimestamp
        );

        interestFloating = calculateInterestFloating(swap.ibtQuantity, mdIbtPrice);
    }

    /// @notice Calculates fixed interest chunk including continuous capitalization for a given swap, closing timestamp and IBT price from IporOracle.
    /// @param notional swap notional, represented in 18 decimals
    /// @param swapFixedInterestRate fixed interest rate on a swap, represented in 18 decimals
    /// @param swapPeriodInSeconds swap period in seconds
    /// @return interestFixed fixed interest chunk, represented in 18 decimals
    function calculateInterestFixed(
        uint256 notional,
        uint256 swapFixedInterestRate,
        uint256 swapPeriodInSeconds
    ) internal pure returns (uint256) {
        return
            notional.addContinuousCompoundInterestUsingRatePeriodMultiplication(
                swapFixedInterestRate * swapPeriodInSeconds
            );
    }

    /// @notice Calculates floating interest chunk for a given ibt quantity and IBT current price
    /// @param ibtQuantity IBT quantity, represented in 18 decimals
    /// @param ibtCurrentPrice IBT price from IporOracle, represented in 18 decimals
    /// @return interestFloating floating interest chunk, represented in 18 decimals
    function calculateInterestFloating(uint256 ibtQuantity, uint256 ibtCurrentPrice) internal pure returns (uint256) {
        //IBTQ * IBTPtc (IBTPtc - interest bearing token price in time when swap is closed)
        return IporMath.division(ibtQuantity * ibtCurrentPrice, 1e18);
    }

    /// @notice Normalizes swap value to collateral value. Absolute value Swap PnL can't be higher than collateral.
    /// @param collateral collateral value, represented in 18 decimals
    /// @param pnlValue swap PnL, represented in 18 decimals
    function normalizePnlValue(uint256 collateral, int256 pnlValue) internal pure returns (int256) {
        int256 intCollateral = collateral.toInt256();

        if (pnlValue > 0) {
            if (pnlValue < intCollateral) {
                return pnlValue;
            } else {
                return intCollateral;
            }
        } else {
            if (pnlValue < -intCollateral) {
                return -intCollateral;
            } else {
                return pnlValue;
            }
        }
    }

    /// @notice Gets swap end timestamp based on swap tenor
    /// @param swap Swap structure
    /// @return swap end timestamp in seconds without 18 decimals
    function getSwapEndTimestamp(AmmTypes.Swap memory swap) internal pure returns (uint256) {
        if (swap.tenor == IporTypes.SwapTenor.DAYS_28) {
            return swap.openTimestamp + 28 days;
        } else if (swap.tenor == IporTypes.SwapTenor.DAYS_60) {
            return swap.openTimestamp + 60 days;
        } else if (swap.tenor == IporTypes.SwapTenor.DAYS_90) {
            return swap.openTimestamp + 90 days;
        } else {
            revert(AmmErrors.UNSUPPORTED_SWAP_TENOR);
        }
    }

    /// @notice Gets swap tenor in seconds
    /// @param tenor Swap tenor
    /// @return swap tenor in seconds
    function getTenorInSeconds(IporTypes.SwapTenor tenor) internal pure returns (uint256) {
        if (tenor == IporTypes.SwapTenor.DAYS_28) {
            return 28 days;
        } else if (tenor == IporTypes.SwapTenor.DAYS_60) {
            return 60 days;
        } else if (tenor == IporTypes.SwapTenor.DAYS_90) {
            return 90 days;
        }
        revert(AmmErrors.UNSUPPORTED_SWAP_TENOR);
    }

    /// @notice Gets swap tenor in days
    /// @param tenor Swap tenor
    /// @return swap tenor in days
    function getTenorInDays(IporTypes.SwapTenor tenor) internal pure returns (uint256) {
        if (tenor == IporTypes.SwapTenor.DAYS_28) {
            return 28;
        } else if (tenor == IporTypes.SwapTenor.DAYS_60) {
            return 60;
        } else if (tenor == IporTypes.SwapTenor.DAYS_90) {
            return 90;
        } else {
            revert(AmmErrors.UNSUPPORTED_SWAP_TENOR);
        }
    }

    /// @notice Splits opening fee amount into liquidity pool and treasury portions
    /// @param openingFeeAmount opening fee amount, represented in 18 decimals
    /// @param openingFeeForTreasurePortionRate opening fee for treasury portion rate taken from Protocol configuration, represented in 18 decimals
    /// @return liquidityPoolAmount liquidity pool portion of opening fee, represented in 18 decimals
    /// @return treasuryAmount treasury portion of opening fee, represented in 18 decimals
    function splitOpeningFeeAmount(
        uint256 openingFeeAmount,
        uint256 openingFeeForTreasurePortionRate
    ) internal pure returns (uint256 liquidityPoolAmount, uint256 treasuryAmount) {
        treasuryAmount = IporMath.division(openingFeeAmount * openingFeeForTreasurePortionRate, 1e18);
        liquidityPoolAmount = openingFeeAmount - treasuryAmount;
    }
}

library SpreadTypes {
    /// @notice structure used to save the weighted notional for the 28 days into storage
    /// timeWeightedNotionalPayFixed without decimals - uint96 - bytes 0-96
    /// lastUpdateTimePayFixed - uint32 - bytes 96-128
    /// timeWeightedNotionalReceiveFixed  without decimals - uint96 - bytes 128-224
    /// lastUpdateTimeReceiveFixed - uint32 - bytes 224-256
    struct WeightedNotionalStorage {
        bytes32 weightedNotional;
    }

    /// @notice Dto for the Weighted Notional
    struct TimeWeightedNotionalMemory {
        /// @notice timeWeightedNotionalPayFixed with 18 decimals
        uint256 timeWeightedNotionalPayFixed;
        /// @notice lastUpdateTimePayFixed timestamp in seconds
        uint256 lastUpdateTimePayFixed;
        /// @notice timeWeightedNotionalReceiveFixed with 18 decimals
        uint256 timeWeightedNotionalReceiveFixed;
        /// @notice lastUpdateTimeReceiveFixed timestamp in seconds
        uint256 lastUpdateTimeReceiveFixed;
        /// @notice storageId from SpreadStorageLibs
        SpreadStorageLibs.StorageId storageId;
    }

    /// @notice Technical structure used in Lens for the Weighted Notional params
    struct TimeWeightedNotionalResponse {
        /// @notice timeWeightedNotionalPayFixed time weighted notional params
        TimeWeightedNotionalMemory timeWeightedNotional;
        string key;
    }
}

/// @title Spread storage library
library SpreadStorageLibs {
    using SafeCast for uint256;
    uint256 private constant STORAGE_SLOT_BASE = 10_000;

    /// Only allowed to append new value to the end of the enum
    enum StorageId {
        // address
        Owner,
        // address
        AppointedOwner,
        // uint256
        Paused,
        // WeightedNotionalStorage
        TimeWeightedNotional28DaysDai,
        TimeWeightedNotional28DaysUsdc,
        TimeWeightedNotional28DaysUsdt,
        TimeWeightedNotional60DaysDai,
        TimeWeightedNotional60DaysUsdc,
        TimeWeightedNotional60DaysUsdt,
        TimeWeightedNotional90DaysDai,
        TimeWeightedNotional90DaysUsdc,
        TimeWeightedNotional90DaysUsdt
    }

    /// @notice Struct which contains owner address of Spread Router
    struct OwnerStorage {
        address owner;
    }

    /// @notice Struct which contains pause flag on Spread Router
    struct PausedStorage {
        uint256 value;
    }

    /// @notice Struct which contains address of appointed owner of Spread Router
    struct AppointedOwnerStorage {
        address appointedOwner;
    }

    /// @notice Saves time weighted notional for a specific asset and tenor
    /// @param timeWeightedNotionalStorageId The storage ID of the time weighted notional
    /// @param timeWeightedNotional The time weighted notional to save
    function saveTimeWeightedNotionalForAssetAndTenor(
        StorageId timeWeightedNotionalStorageId,
        SpreadTypes.TimeWeightedNotionalMemory memory timeWeightedNotional
    ) internal {
        _checkTimeWeightedNotional(timeWeightedNotionalStorageId);
        uint256 timeWeightedNotionalPayFixedTemp;
        uint256 timeWeightedNotionalReceiveFixedTemp;
        unchecked {
            timeWeightedNotionalPayFixedTemp = timeWeightedNotional.timeWeightedNotionalPayFixed / 1e18;

            timeWeightedNotionalReceiveFixedTemp = timeWeightedNotional.timeWeightedNotionalReceiveFixed / 1e18;
        }

        uint96 timeWeightedNotionalPayFixed = timeWeightedNotionalPayFixedTemp.toUint96();
        uint32 lastUpdateTimePayFixed = timeWeightedNotional.lastUpdateTimePayFixed.toUint32();
        uint96 timeWeightedNotionalReceiveFixed = timeWeightedNotionalReceiveFixedTemp.toUint96();
        uint32 lastUpdateTimeReceiveFixed = timeWeightedNotional.lastUpdateTimeReceiveFixed.toUint32();
        uint256 slotAddress = _getStorageSlot(timeWeightedNotionalStorageId);
        assembly {
            let value := add(
                timeWeightedNotionalPayFixed,
                add(
                    shl(96, lastUpdateTimePayFixed),
                    add(shl(128, timeWeightedNotionalReceiveFixed), shl(224, lastUpdateTimeReceiveFixed))
                )
            )
            sstore(slotAddress, value)
        }
    }

    /// @notice Gets the time-weighted notional for a specific storage ID representing an asset and tenor
    /// @param timeWeightedNotionalStorageId The storage ID of the time weighted notional
    function getTimeWeightedNotionalForAssetAndTenor(
        StorageId timeWeightedNotionalStorageId
    ) internal view returns (SpreadTypes.TimeWeightedNotionalMemory memory weightedNotional28Days) {
        _checkTimeWeightedNotional(timeWeightedNotionalStorageId);
        uint256 timeWeightedNotionalPayFixed;
        uint256 lastUpdateTimePayFixed;
        uint256 timeWeightedNotionalReceiveFixed;
        uint256 lastUpdateTimeReceiveFixed;
        uint256 slotAddress = _getStorageSlot(timeWeightedNotionalStorageId);
        assembly {
            let slotValue := sload(slotAddress)
            timeWeightedNotionalPayFixed := mul(and(slotValue, 0xFFFFFFFFFFFFFFFFFFFFFFFF), 1000000000000000000)
            lastUpdateTimePayFixed := and(shr(96, slotValue), 0xFFFFFFFF)
            timeWeightedNotionalReceiveFixed := mul(
                and(shr(128, slotValue), 0xFFFFFFFFFFFFFFFFFFFFFFFF),
                1000000000000000000
            )
            lastUpdateTimeReceiveFixed := and(shr(224, slotValue), 0xFFFFFFFF)
        }

        return
            SpreadTypes.TimeWeightedNotionalMemory({
                timeWeightedNotionalPayFixed: timeWeightedNotionalPayFixed,
                lastUpdateTimePayFixed: lastUpdateTimePayFixed,
                timeWeightedNotionalReceiveFixed: timeWeightedNotionalReceiveFixed,
                lastUpdateTimeReceiveFixed: lastUpdateTimeReceiveFixed,
                storageId: timeWeightedNotionalStorageId
            });
    }

    /// @notice Gets all time weighted notional storage IDs
    function getAllStorageId() internal pure returns (StorageId[] memory storageIds, string[] memory keys) {
        storageIds = new StorageId[](9);
        keys = new string[](9);
        storageIds[0] = StorageId.TimeWeightedNotional28DaysDai;
        keys[0] = "TimeWeightedNotional28DaysDai";
        storageIds[1] = StorageId.TimeWeightedNotional28DaysUsdc;
        keys[1] = "TimeWeightedNotional28DaysUsdc";
        storageIds[2] = StorageId.TimeWeightedNotional28DaysUsdt;
        keys[2] = "TimeWeightedNotional28DaysUsdt";
        storageIds[3] = StorageId.TimeWeightedNotional60DaysDai;
        keys[3] = "TimeWeightedNotional60DaysDai";
        storageIds[4] = StorageId.TimeWeightedNotional60DaysUsdc;
        keys[4] = "TimeWeightedNotional60DaysUsdc";
        storageIds[5] = StorageId.TimeWeightedNotional60DaysUsdt;
        keys[5] = "TimeWeightedNotional60DaysUsdt";
        storageIds[6] = StorageId.TimeWeightedNotional90DaysDai;
        keys[6] = "TimeWeightedNotional90DaysDai";
        storageIds[7] = StorageId.TimeWeightedNotional90DaysUsdc;
        keys[7] = "TimeWeightedNotional90DaysUsdc";
        storageIds[8] = StorageId.TimeWeightedNotional90DaysUsdt;
        keys[8] = "TimeWeightedNotional90DaysUsdt";
    }

    /// @notice Gets the owner of the Spread Router
    /// @return owner The owner of the Spread Router
    function getOwner() internal pure returns (OwnerStorage storage owner) {
        uint256 slotAddress = _getStorageSlot(StorageId.Owner);
        assembly {
            owner.slot := slotAddress
        }
    }

    /// @notice Gets the appointed owner of the Spread Router
    /// @return appointedOwner The appointed owner of the Spread Router
    function getAppointedOwner() internal pure returns (AppointedOwnerStorage storage appointedOwner) {
        uint256 slotAddress = _getStorageSlot(StorageId.AppointedOwner);
        assembly {
            appointedOwner.slot := slotAddress
        }
    }

    /// @notice Gets the paused state of the Spread Router
    /// @return paused The paused state of the Spread Router
    function getPaused() internal pure returns (PausedStorage storage paused) {
        uint256 slotAddress = _getStorageSlot(StorageId.Paused);
        assembly {
            paused.slot := slotAddress
        }
    }

    function _getStorageSlot(StorageId storageId) internal pure returns (uint256 slot) {
        slot = uint256(storageId) + STORAGE_SLOT_BASE;
    }

    function _checkTimeWeightedNotional(StorageId storageId) internal pure {
        require(
            storageId == StorageId.TimeWeightedNotional28DaysDai ||
                storageId == StorageId.TimeWeightedNotional28DaysUsdc ||
                storageId == StorageId.TimeWeightedNotional28DaysUsdt ||
                storageId == StorageId.TimeWeightedNotional60DaysDai ||
                storageId == StorageId.TimeWeightedNotional60DaysUsdc ||
                storageId == StorageId.TimeWeightedNotional60DaysUsdt ||
                storageId == StorageId.TimeWeightedNotional90DaysDai ||
                storageId == StorageId.TimeWeightedNotional90DaysUsdc ||
                storageId == StorageId.TimeWeightedNotional90DaysUsdt,
            AmmErrors.STORAGE_ID_IS_NOT_TIME_WEIGHTED_NOTIONAL
        );
    }
}

library CalculateTimeWeightedNotionalLibs {
    /// @notice calculate amm lp depth
    /// @param liquidityPoolBalance liquidity pool balance
    /// @param totalCollateralPayFixed total collateral pay fixed
    /// @param totalCollateralReceiveFixed total collateral receive fixed
    function calculateLpDepth(
        uint256 liquidityPoolBalance,
        uint256 totalCollateralPayFixed,
        uint256 totalCollateralReceiveFixed
    ) internal pure returns (uint256 lpDepth) {
        if (totalCollateralPayFixed >= totalCollateralReceiveFixed) {
            lpDepth = liquidityPoolBalance + totalCollateralReceiveFixed - totalCollateralPayFixed;
        } else {
            lpDepth = liquidityPoolBalance + totalCollateralPayFixed - totalCollateralReceiveFixed;
        }
    }

    /// @notice calculate weighted notional
    /// @param timeWeightedNotional weighted notional value
    /// @param timeFromLastUpdate time from last update in seconds
    /// @param tenorInSeconds tenor in seconds
    function calculateTimeWeightedNotional(
        uint256 timeWeightedNotional,
        uint256 timeFromLastUpdate,
        uint256 tenorInSeconds
    ) internal pure returns (uint256) {
        if (timeFromLastUpdate >= tenorInSeconds) {
            return 0;
        }
        uint256 newTimeWeightedNotional = IporMath.divisionWithoutRound(
            timeWeightedNotional * (tenorInSeconds - timeFromLastUpdate),
            tenorInSeconds
        );
        return newTimeWeightedNotional;
    }

    /// @notice Updates the time-weighted notional value for the receive fixed leg.
    /// @param timeWeightedNotional The memory struct containing the time-weighted notional information.
    /// @param newSwapNotional The new swap notional value.
    /// @param tenorInSeconds Tenor in seconds.
    /// @dev This function is internal and used to update the time-weighted notional value for the receive fixed leg.
    function updateTimeWeightedNotionalReceiveFixed(
        SpreadTypes.TimeWeightedNotionalMemory memory timeWeightedNotional,
        uint256 newSwapNotional,
        uint256 tenorInSeconds
    ) internal {
        if (timeWeightedNotional.timeWeightedNotionalReceiveFixed == 0) {
            timeWeightedNotional.timeWeightedNotionalReceiveFixed = calculateTimeWeightedNotional(
                newSwapNotional,
                0,
                tenorInSeconds
            );
        } else {
            uint256 oldWeightedNotionalReceiveFixed = calculateTimeWeightedNotional(
                timeWeightedNotional.timeWeightedNotionalReceiveFixed,
                block.timestamp - timeWeightedNotional.lastUpdateTimeReceiveFixed,
                tenorInSeconds
            );
            timeWeightedNotional.timeWeightedNotionalReceiveFixed = newSwapNotional + oldWeightedNotionalReceiveFixed;
        }
        timeWeightedNotional.lastUpdateTimeReceiveFixed = block.timestamp;
        SpreadStorageLibs.saveTimeWeightedNotionalForAssetAndTenor(timeWeightedNotional.storageId, timeWeightedNotional);
    }

    /// @notice Updates the time-weighted notional value for the pay fixed leg.
    /// @param timeWeightedNotional The memory struct containing the time-weighted notional information.
    /// @param newSwapNotional The new swap notional value.
    /// @param tenorInSeconds Tenor in seconds.
    /// @dev This function is internal and used to update the time-weighted notional value for the pay fixed leg.
    function updateTimeWeightedNotionalPayFixed(
        SpreadTypes.TimeWeightedNotionalMemory memory timeWeightedNotional,
        uint256 newSwapNotional,
        uint256 tenorInSeconds
    ) internal {
        if (timeWeightedNotional.timeWeightedNotionalPayFixed == 0) {
            timeWeightedNotional.timeWeightedNotionalPayFixed = calculateTimeWeightedNotional(
                newSwapNotional,
                0,
                tenorInSeconds
            );
        } else {
            uint256 oldWeightedNotionalPayFixed = calculateTimeWeightedNotional(
                timeWeightedNotional.timeWeightedNotionalPayFixed,
                block.timestamp - timeWeightedNotional.lastUpdateTimePayFixed,
                tenorInSeconds
            );
            timeWeightedNotional.timeWeightedNotionalPayFixed = newSwapNotional + oldWeightedNotionalPayFixed;
        }
        timeWeightedNotional.lastUpdateTimePayFixed = block.timestamp;
        SpreadStorageLibs.saveTimeWeightedNotionalForAssetAndTenor(timeWeightedNotional.storageId, timeWeightedNotional);
    }

    /// @notice Calculates the time-weighted notional values for the pay fixed and receive fixed legs.
    /// @param timeWeightedNotionalStorageIds The array of storage IDs representing the time-weighted notional storage locations.
    /// @param tenorsInSeconds The array of maturities corresponding to each storage ID.
    /// @param selectedTenorInSeconds The tenor in seconds used to calculate the time-weighted notional values.
    /// @return timeWeightedNotionalPayFixed The aggregated time-weighted notional value for the pay fixed leg.
    /// @return timeWeightedNotionalReceiveFixed The aggregated time-weighted notional value for the receive fixed leg.
    /// @dev This function is internal and used to calculate the aggregated time-weighted notional values for multiple storage IDs and maturities.
    function getTimeWeightedNotional(
        SpreadStorageLibs.StorageId[] memory timeWeightedNotionalStorageIds,
        uint256[] memory tenorsInSeconds,
        uint256 selectedTenorInSeconds
    ) internal view returns (uint256 timeWeightedNotionalPayFixed, uint256 timeWeightedNotionalReceiveFixed) {
        uint256 length = timeWeightedNotionalStorageIds.length;

        SpreadTypes.TimeWeightedNotionalMemory memory timeWeightedNotional;
        uint256 timeWeightedNotionalPayFixedIteration;
        uint256 timeWeightedNotionalReceiveFixedIteration;

        for (uint256 i; i != length; ) {
            timeWeightedNotional = SpreadStorageLibs.getTimeWeightedNotionalForAssetAndTenor(timeWeightedNotionalStorageIds[i]);
            timeWeightedNotionalPayFixedIteration = _isTimeWeightedNotionalRecalculationRequired(
                timeWeightedNotional.lastUpdateTimePayFixed,
                tenorsInSeconds[i],
                selectedTenorInSeconds
            )
                ? calculateTimeWeightedNotional(
                    timeWeightedNotional.timeWeightedNotionalPayFixed,
                    block.timestamp - timeWeightedNotional.lastUpdateTimePayFixed,
                    tenorsInSeconds[i]
                )
                : timeWeightedNotional.timeWeightedNotionalPayFixed;
            timeWeightedNotionalPayFixed = timeWeightedNotionalPayFixed + timeWeightedNotionalPayFixedIteration;

            timeWeightedNotionalReceiveFixedIteration = _isTimeWeightedNotionalRecalculationRequired(
                timeWeightedNotional.lastUpdateTimeReceiveFixed,
                tenorsInSeconds[i],
                selectedTenorInSeconds
            )
                ? calculateTimeWeightedNotional(
                    timeWeightedNotional.timeWeightedNotionalReceiveFixed,
                    block.timestamp - timeWeightedNotional.lastUpdateTimeReceiveFixed,
                    tenorsInSeconds[i]
                )
                : timeWeightedNotional.timeWeightedNotionalReceiveFixed;
            timeWeightedNotionalReceiveFixed = timeWeightedNotionalReceiveFixedIteration + timeWeightedNotionalReceiveFixed;

            unchecked {
                ++i;
            }
        }
    }

    /// @notice Determines if the time-weighted notional should be recalculated based on the last update time and tenors.
    /// @param lastUpdateTime The last time the notional was updated.
    /// @param iterationTenorInSeconds The tenor duration in seconds.
    /// @param selectedTenorInSeconds The duration in seconds for which the spread should be calculated for a given tenor.
    /// @dev This function is internal and used to decide if a recalculation of the time-weighted notional is necessary.
    function _isTimeWeightedNotionalRecalculationRequired(
        uint256 lastUpdateTime,
        uint256 iterationTenorInSeconds,
        uint256 selectedTenorInSeconds
    ) internal view returns (bool) {
        return iterationTenorInSeconds + lastUpdateTime < block.timestamp + selectedTenorInSeconds;
    }
}

/// @dev It is not recommended to use service contract directly, should be used only through SpreadRouter.
contract SpreadCloseSwapService is ISpreadCloseSwapService {
    using IporContractValidator for address;
    using SafeCast for uint256;

    address internal immutable _dai;
    address internal immutable _usdc;
    address internal immutable _usdt;

    constructor(address dai, address usdc, address usdt) {
        _dai = dai.checkAddress();
        _usdc = usdc.checkAddress();
        _usdt = usdt.checkAddress();
    }

    function getSupportedAssets() external view returns (address[] memory) {
        address[] memory assets = new address[](3);
        assets[0] = _dai;
        assets[1] = _usdc;
        assets[2] = _usdt;
        return assets;
    }

    function updateTimeWeightedNotionalOnClose(
        address asset,
        uint256 direction,
        IporTypes.SwapTenor tenor,
        uint256 swapNotional,
        AmmInternalTypes.OpenSwapItem memory closedSwap,
        address ammStorageAddress
    ) external override {
        // @dev when timestamp is 0, it means that the swap was open in ipor-protocol v1 .
        if (closedSwap.openSwapTimestamp == 0) {
            return;
        }
        uint256 tenorInSeconds = IporSwapLogic.getTenorInSeconds(tenor);
        SpreadStorageLibs.StorageId storageId = _getStorageId(asset, tenor);
        SpreadTypes.TimeWeightedNotionalMemory memory timeWeightedNotional = SpreadStorageLibs
            .getTimeWeightedNotionalForAssetAndTenor(storageId);

        uint256 timeWeightedNotionalAmount = direction == 0
            ? timeWeightedNotional.timeWeightedNotionalPayFixed
            : timeWeightedNotional.timeWeightedNotionalReceiveFixed;
        uint256 timeOfLastUpdate = direction == 0
            ? timeWeightedNotional.lastUpdateTimePayFixed
            : timeWeightedNotional.lastUpdateTimeReceiveFixed;

        uint256 timeWeightedNotionalToRemove = CalculateTimeWeightedNotionalLibs.calculateTimeWeightedNotional(
            swapNotional,
            // @dev timeOfLastUpdate should be greater than closedSwap.openSwapTimestamp
            timeOfLastUpdate - closedSwap.openSwapTimestamp,
            tenorInSeconds
        );

        uint256 actualTimeWeightedNotionalToSave;
        if (timeWeightedNotionalAmount > timeWeightedNotionalToRemove) {
            actualTimeWeightedNotionalToSave = timeWeightedNotionalAmount - timeWeightedNotionalToRemove;
        }

        if (closedSwap.nextSwapId == 0) {
            AmmInternalTypes.OpenSwapItem memory lastOpenSwap = IAmmStorage(ammStorageAddress).getLastOpenedSwap(
                tenor,
                direction
            );
            uint256 swapTimePast = block.timestamp - uint256(lastOpenSwap.openSwapTimestamp);
            if (tenorInSeconds <= swapTimePast) {
                actualTimeWeightedNotionalToSave = 0;
                swapTimePast = 0;
            }
            if (direction == 0) {
                timeWeightedNotional.lastUpdateTimePayFixed = lastOpenSwap.openSwapTimestamp;
                timeWeightedNotional.timeWeightedNotionalPayFixed =
                    (actualTimeWeightedNotionalToSave * tenorInSeconds) /
                    (tenorInSeconds - swapTimePast);
            } else {
                timeWeightedNotional.lastUpdateTimeReceiveFixed = lastOpenSwap.openSwapTimestamp;
                timeWeightedNotional.timeWeightedNotionalReceiveFixed =
                    (actualTimeWeightedNotionalToSave * tenorInSeconds) /
                    (tenorInSeconds - swapTimePast);
            }
        } else {
            if (direction == 0) {
                timeWeightedNotional.timeWeightedNotionalPayFixed = actualTimeWeightedNotionalToSave;
            } else {
                timeWeightedNotional.timeWeightedNotionalReceiveFixed = actualTimeWeightedNotionalToSave;
            }
        }

        SpreadStorageLibs.saveTimeWeightedNotionalForAssetAndTenor(storageId, timeWeightedNotional);
    }

    function _getStorageId(
        address asset,
        IporTypes.SwapTenor tenor
    ) internal view returns (SpreadStorageLibs.StorageId storageId) {
        if (asset == _dai) {
            if (tenor == IporTypes.SwapTenor.DAYS_28) {
                storageId = SpreadStorageLibs.StorageId.TimeWeightedNotional28DaysDai;
            } else if (tenor == IporTypes.SwapTenor.DAYS_60) {
                storageId = SpreadStorageLibs.StorageId.TimeWeightedNotional60DaysDai;
            } else if (tenor == IporTypes.SwapTenor.DAYS_90) {
                storageId = SpreadStorageLibs.StorageId.TimeWeightedNotional90DaysDai;
            }
        } else if (asset == _usdc) {
            if (tenor == IporTypes.SwapTenor.DAYS_28) {
                storageId = SpreadStorageLibs.StorageId.TimeWeightedNotional28DaysUsdc;
            } else if (tenor == IporTypes.SwapTenor.DAYS_60) {
                storageId = SpreadStorageLibs.StorageId.TimeWeightedNotional60DaysUsdc;
            } else if (tenor == IporTypes.SwapTenor.DAYS_90) {
                storageId = SpreadStorageLibs.StorageId.TimeWeightedNotional90DaysUsdc;
            }
        } else if (asset == _usdt) {
            if (tenor == IporTypes.SwapTenor.DAYS_28) {
                storageId = SpreadStorageLibs.StorageId.TimeWeightedNotional28DaysUsdt;
            } else if (tenor == IporTypes.SwapTenor.DAYS_60) {
                storageId = SpreadStorageLibs.StorageId.TimeWeightedNotional60DaysUsdt;
            } else if (tenor == IporTypes.SwapTenor.DAYS_90) {
                storageId = SpreadStorageLibs.StorageId.TimeWeightedNotional90DaysUsdt;
            }
        } else {
            revert(IporErrors.WRONG_ADDRESS);
        }
        if (uint256(storageId) == 0) {
            revert(AmmErrors.UNSUPPORTED_SWAP_TENOR);
        }
    }
}