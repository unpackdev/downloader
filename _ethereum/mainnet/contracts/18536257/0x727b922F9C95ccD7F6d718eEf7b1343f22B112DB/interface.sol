// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

interface VaultV2Interface {
    function decimals() external view returns (uint8);

    function asset() external view returns (address);

    // From ERC20Upgradable
    function balanceOf(address account) external view returns (uint256);

    // iTokenV2 current exchange price.
    function exchangePrice() external view returns (uint256);

    function revenueExchangePrice() external view returns (uint256);

    function aggrMaxVaultRatio() external view returns (uint256);

    function withdrawFeeAbsoluteMin() external view returns (uint256);

    struct ProtocolAssetsInStETH {
        uint256 stETH; // supply
        uint256 wETH; // borrow
    }

    struct ProtocolAssetsInWstETH {
        uint256 wstETH; // supply
        uint256 wETH; // borrow
    }

    struct IdealBalances {
        uint256 stETH;
        uint256 wstETH;
        uint256 wETH;
    }

    struct NetAssetsHelper {
        ProtocolAssetsInStETH aaveV2;
        ProtocolAssetsInWstETH aaveV3;
        ProtocolAssetsInWstETH compoundV3;
        ProtocolAssetsInWstETH euler;
        ProtocolAssetsInStETH morphoAaveV2;
        ProtocolAssetsInWstETH morphoAaveV3;
        ProtocolAssetsInWstETH spark;
        IdealBalances vaultBalances;
        IdealBalances dsaBalances;
    }

    function getNetAssets()
        external
        view
        returns (
            uint256 totalAssets_, // Total assets(collaterals + ideal balances + queued withdraws) inlcuding reveune
            uint256 totalDebt_, // Total debt
            uint256 netAssets_, // Total assets - Total debt - Reveune
            uint256 aggregatedRatio_, // Aggregated ratio of vault (Total debt/ (Total assets - revenue))
            NetAssetsHelper memory assets_
        );

    function maxRiskRatio(
        uint8 protocolId
    ) external view returns (uint256 maxRiskRatio);

    function vaultDSA() external view returns (address);

    function revenueFeePercentage() external view returns (uint256);

    function withdrawalFeePercentage() external view returns (uint256);

    function leverageMaxUnitAmountLimit() external view returns (uint256);

    function revenue() external view returns (uint256);

    // iTokenV2 total supply.
    function totalSupply() external view returns (uint256);

    function getRatioAaveV2()
        external
        view
        returns (uint256 stEthAmount, uint256 ethAmount, uint256 ratio);

    function getRatioAaveV3(
        uint256 stEthPerWsteth // Optional
    )
        external
        view
        returns (
            uint256 wstEthAmount,
            uint256 stEthAmount,
            uint256 ethAmount,
            uint256 ratio
        );

    function getRatioCompoundV3(
        uint256 stEthPerWsteth // Optional
    )
        external
        view
        returns (
            uint256 wstEthAmount,
            uint256 stEthAmount,
            uint256 ethAmount,
            uint256 ratio
        );

    function getRatioEuler(
        uint256 stEthPerWsteth // Optional
    )
        external
        view
        returns (
            uint256 wstEthAmount,
            uint256 stEthAmount,
            uint256 ethAmount,
            uint256 ratio
        );

    function getRatioMorphoAaveV2()
        external
        view
        returns (
            uint256 stEthAmount_, // Aggreagted value of stETH in Pool and P2P
            uint256 stEthAmountPool_,
            uint256 stEthAmountP2P_,
            uint256 ethAmount_, // Aggreagted value of eth in Pool and P2P
            uint256 ethAmountPool_,
            uint256 ethAmountP2P_,
            uint256 ratio_
        );

    function getRatioMorphoAaveV3(
        uint256 stEthPerWsteth_ // Optional
    )
        external
        view
        returns (
            uint256 wstEthAmount_,
            uint256 stEthAmount_,
            uint256 ethAmount_,
            uint256 ratio_
        );

    function getRatioSpark(
        uint256 stEthPerWsteth_
    )
        external
        view
        returns (
            uint256 wstEthAmount_,
            uint256 stEthAmount_,
            uint256 ethAmount_,
            uint256 ratio_
        );
}

interface IMorphoAaveV3 {
    function marketsCreated() external view returns (address[] memory);

    /// @notice Contains the market side indexes as uint256 instead of uint128.
    struct MarketSideIndexes256 {
        uint256 poolIndex; // The pool index (in ray).
        uint256 p2pIndex; // The peer-to-peer index (in ray).
    }

    /// @notice Contains the indexes as uint256 instead of uint128.
    struct Indexes256 {
        MarketSideIndexes256 supply; // The `MarketSideIndexes` related to the supply as uint256.
        MarketSideIndexes256 borrow; // The `MarketSideIndexes` related to the borrow as uint256.
    }

    /// @notice Returns the updated indexes (peer-to-peer and pool).
    function updatedIndexes(
        address underlying
    ) external view returns (Indexes256 memory);

    /// @notice Returns the total borrow balance of `user` on the `underlying` market (in underlying).
    function borrowBalance(
        address underlying,
        address user
    ) external view returns (uint256);

    /// @notice Returns the supply collateral balance of `user` on the `underlying` market (in underlying).
    function collateralBalance(
        address underlying,
        address user
    ) external view returns (uint256);

    /// @notice Returns the scaled balance of `user` on the `underlying` market, supplied on pool & used as collateral (with `underlying` decimals).
    function scaledCollateralBalance(
        address underlying,
        address user
    ) external view returns (uint256);

    /// @notice Returns the scaled balance of `user` on the `underlying` market, borrowed peer-to-peer (with `underlying` decimals).
    function scaledP2PBorrowBalance(
        address underlying,
        address user
    ) external view returns (uint256);

    /// @notice Returns the scaled balance of `user` on the `underlying` market, borrowed from pool (with `underlying` decimals).
    function scaledPoolBorrowBalance(
        address underlying,
        address user
    ) external view returns (uint256);

    function market(address underlying) external view returns (Market memory);

    function scaledP2PSupplyBalance(
        address underlying,
        address user
    ) external view returns (uint256);

    function scaledPoolSupplyBalance(
        address underlying,
        address user
    ) external view returns (uint256);

    struct ReserveData {
        //stores the reserve configuration
        ReserveConfigurationMap configuration;
        //the liquidity index. Expressed in ray
        uint128 liquidityIndex;
        //the current supply rate. Expressed in ray
        uint128 currentLiquidityRate;
        //variable borrow index. Expressed in ray
        uint128 variableBorrowIndex;
        //the current variable borrow rate. Expressed in ray
        uint128 currentVariableBorrowRate;
        //the current stable borrow rate. Expressed in ray
        uint128 currentStableBorrowRate;
        //timestamp of last update
        uint40 lastUpdateTimestamp;
        //the id of the reserve. Represents the position in the list of the active reserves
        uint16 id;
        //aToken address
        address aTokenAddress;
        //stableDebtToken address
        address stableDebtTokenAddress;
        //variableDebtToken address
        address variableDebtTokenAddress;
        //address of the interest rate strategy
        address interestRateStrategyAddress;
        //the current treasury balance, scaled
        uint128 accruedToTreasury;
        //the outstanding unbacked aTokens minted through the bridging feature
        uint128 unbacked;
        //the outstanding debt borrowed against this asset in isolation mode
        uint128 isolationModeTotalDebt;
    }

    struct ReserveConfigurationMap {
        //bit 0-15: LTV
        //bit 16-31: Liq. threshold
        //bit 32-47: Liq. bonus
        //bit 48-55: Decimals
        //bit 56: reserve is active
        //bit 57: reserve is frozen
        //bit 58: borrowing is enabled
        //bit 59: stable rate borrowing enabled
        //bit 60: asset is paused
        //bit 61: borrowing in isolation mode is enabled
        //bit 62-63: reserved
        //bit 64-79: reserve factor
        //bit 80-115 borrow cap in whole tokens, borrowCap == 0 => no cap
        //bit 116-151 supply cap in whole tokens, supplyCap == 0 => no cap
        //bit 152-167 liquidation protocol fee
        //bit 168-175 eMode category
        //bit 176-211 unbacked mint cap in whole tokens, unbackedMintCap == 0 => minting disabled
        //bit 212-251 debt ceiling for isolation mode with (ReserveConfiguration::DEBT_CEILING_DECIMALS) decimals
        //bit 252-255 unused

        uint256 data;
    }

    struct Market {
        // SLOT 0-1
        Indexes indexes;
        // SLOT 2-5
        Deltas deltas; // 1024 bits
        // SLOT 6
        address underlying; // 160 bits
        PauseStatuses pauseStatuses; // 80 bits
        bool isCollateral; // 8 bits
        // SLOT 7
        address variableDebtToken; // 160 bits
        uint32 lastUpdateTimestamp; // 32 bits
        uint16 reserveFactor; // 16 bits
        uint16 p2pIndexCursor; // 16 bits
        // SLOT 8
        address aToken; // 160 bits
        // SLOT 9
        address stableDebtToken; // 160 bits
        // SLOT 10
        uint256 idleSupply; // 256 bits
    }

    /// @notice Contains the indexes for both `supply` and `borrow`.
    struct Indexes {
        MarketSideIndexes supply; // The `MarketSideIndexes` related to the supply side.
        MarketSideIndexes borrow; // The `MarketSideIndexes` related to the borrow side.
    }

    /// @notice Contains the delta data for both `supply` and `borrow`.
    struct Deltas {
        MarketSideDelta supply; // The `MarketSideDelta` related to the supply side.
        MarketSideDelta borrow; // The `MarketSideDelta` related to the borrow side.
    }

    /// @notice Contains the different pauses statuses possible in Morpho.
    struct PauseStatuses {
        bool isP2PDisabled;
        bool isSupplyPaused;
        bool isSupplyCollateralPaused;
        bool isBorrowPaused;
        bool isWithdrawPaused;
        bool isWithdrawCollateralPaused;
        bool isRepayPaused;
        bool isLiquidateCollateralPaused;
        bool isLiquidateBorrowPaused;
        bool isDeprecated;
    }

    /// @notice Contains the market side indexes.
    struct MarketSideIndexes {
        uint128 poolIndex; // The pool index (in ray).
        uint128 p2pIndex; // The peer-to-peer index (in ray).
    }

    /// @notice Contains the market side delta data.
    struct MarketSideDelta {
        uint256 scaledDelta; // The delta amount in pool unit.
        uint256 scaledP2PTotal; // The total peer-to-peer amount in peer-to-peer unit.
    }
}

interface IAaveV3AddressProvider {
    function getPool() external view returns (address);
}

interface IAaveV3Pool {
    struct ReserveConfigurationMap {
        //bit 0-15: LTV
        //bit 16-31: Liq. threshold
        //bit 32-47: Liq. bonus
        //bit 48-55: Decimals
        //bit 56: reserve is active
        //bit 57: reserve is frozen
        //bit 58: borrowing is enabled
        //bit 59: stable rate borrowing enabled
        //bit 60: asset is paused
        //bit 61: borrowing in isolation mode is enabled
        //bit 62-63: reserved
        //bit 64-79: reserve factor
        //bit 80-115 borrow cap in whole tokens, borrowCap == 0 => no cap
        //bit 116-151 supply cap in whole tokens, supplyCap == 0 => no cap
        //bit 152-167 liquidation protocol fee
        //bit 168-175 eMode category
        //bit 176-211 unbacked mint cap in whole tokens, unbackedMintCap == 0 => minting disabled
        //bit 212-251 debt ceiling for isolation mode with (ReserveConfiguration::DEBT_CEILING_DECIMALS) decimals
        //bit 252-255 unused

        uint256 data;
    }

    struct ReserveData {
        //stores the reserve configuration
        ReserveConfigurationMap configuration;
        //the liquidity index. Expressed in ray
        uint128 liquidityIndex;
        //the current supply rate. Expressed in ray
        uint128 currentLiquidityRate;
        //variable borrow index. Expressed in ray
        uint128 variableBorrowIndex;
        //the current variable borrow rate. Expressed in ray
        uint128 currentVariableBorrowRate;
        //the current stable borrow rate. Expressed in ray
        uint128 currentStableBorrowRate;
        //timestamp of last update
        uint40 lastUpdateTimestamp;
        //the id of the reserve. Represents the position in the list of the active reserves
        uint16 id;
        //aToken address
        address aTokenAddress;
        //stableDebtToken address
        address stableDebtTokenAddress;
        //variableDebtToken address
        address variableDebtTokenAddress;
        //address of the interest rate strategy
        address interestRateStrategyAddress;
        //the current treasury balance, scaled
        uint128 accruedToTreasury;
        //the outstanding unbacked aTokens minted through the bridging feature
        uint128 unbacked;
        //the outstanding debt borrowed against this asset in isolation mode
        uint128 isolationModeTotalDebt;
    }

    /**
     * @notice Returns the state and configuration of the reserve
     * @param asset The address of the underlying asset of the reserve
     * @return The state and configuration data of the reserve
     */
    function getReserveData(
        address asset
    ) external view returns (ReserveData memory);
}

interface IAaveV2AddressProvider {
    function getPriceOracle() external view returns (address);

    function getLendingPool() external view returns (address);
}

interface IAavePriceOracle {
    function getAssetPrice(address _asset) external view returns (uint256);
}

interface IWsteth {
    function tokensPerStEth() external view returns (uint256);

    function getStETHByWstETH(
        uint256 _wstETHAmount
    ) external view returns (uint256);

    function stEthPerToken() external view returns (uint256);
}

interface IAaveV2DataProvider {
    function getReserveData(
        address asset
    )
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256, // liquidityRate (IN RAY) (100% => 1e29)
            uint256, // variableBorrowRate (IN RAY) (100% => 1e29)
            uint256,
            uint256,
            uint256,
            uint256,
            uint40
        );
}

interface IAaveV3DataProvider {
    function getReserveData(
        address asset
    )
        external
        view
        returns (
            uint256 unbacked,
            uint256 accruedToTreasuryScaled,
            uint256 totalAToken,
            uint256 totalStableDebt,
            uint256 totalVariableDebt,
            uint256 liquidityRate,
            uint256 variableBorrowRate,
            uint256 stableBorrowRate,
            uint256 averageStableBorrowRate,
            uint256 liquidityIndex,
            uint256 variableBorrowIndex,
            uint40 lastUpdateTimestamp
        );
}

interface ISparkDataProvider {
    // @notice Returns the reserve data
    function getReserveData(
        address asset
    )
        external
        view
        returns (
            uint256 unbacked,
            uint256 accruedToTreasuryScaled,
            uint256 totalSPToken,
            uint256 totalStableDebt,
            uint256 totalVariableDebt,
            uint256 liquidityRate,
            uint256 variableBorrowRate,
            uint256 stableBorrowRate,
            uint256 averageStableBorrowRate,
            uint256 liquidityIndex,
            uint256 variableBorrowIndex,
            uint40 lastUpdateTimestamp
        );
}

interface IComet {
    // The current protocol utilization percentage as a decimal, represented by an unsigned integer, scaled up by 10 ^ 18. E.g. 1e17 or 100000000000000000 is 10% utilization.
    function getUtilization() external view returns (uint);

    // The per second supply rate as the decimal representation of a percentage scaled up by 10 ^ 18. E.g. 317100000 indicates, roughly, a 1% APR.
    function getSupplyRate(uint utilization) external view returns (uint64);

    // The per second borrow rate as the decimal representation of a percentage scaled up by 10 ^ 18. E.g. 317100000 indicates, roughly, a 1% APR.
    function getBorrowRate(uint utilization) external view returns (uint64);
}

interface IEulerSimpleView {
    // underlying -> interest rate
    function interestRates(
        address underlying
    ) external view returns (uint borrowSPY, uint borrowAPY, uint supplyAPY);
}

interface IMorphoAaveLens {
    function getRatesPerYear(
        address _poolToken
    )
        external
        view
        returns (
            uint256 p2pSupplyRate,
            uint256 p2pBorrowRate,
            uint256 poolSupplyRate,
            uint256 poolBorrowRate
        );
}

interface ILiteVaultV1 {
    function balanceOf(address account) external view returns (uint256);

    function getCurrentExchangePrice()
        external
        view
        returns (uint256 exchangePrice_, uint256 newRevenue_);
}

interface IChainlink {
    function latestAnswer() external view returns (int256 answer);
}

interface ILidoWithdrawalQueue {
    // code below from Lido WithdrawalQueueBase.sol
    // see https://github.com/lidofinance/lido-dao/blob/v2.0.0-beta.3/contracts/0.8.9/WithdrawalQueueBase.sol

    /// @notice output format struct for `_getWithdrawalStatus()` method
    struct WithdrawalRequestStatus {
        /// @notice stETH token amount that was locked on withdrawal queue for this request
        uint256 amountOfStETH;
        /// @notice amount of stETH shares locked on withdrawal queue for this request
        uint256 amountOfShares;
        /// @notice address that can claim or transfer this request
        address owner;
        /// @notice timestamp of when the request was created, in seconds
        uint256 timestamp;
        /// @notice true, if request is finalized
        bool isFinalized;
        /// @notice true, if request is claimed. Request is claimable if (isFinalized && !isClaimed)
        bool isClaimed;
    }

    /// @notice length of the checkpoints. Last possible value for the claim hint
    function getLastCheckpointIndex() external view returns (uint256);

    // code below from Lido WithdrawalQueue.sol
    // see https://github.com/lidofinance/lido-dao/blob/v2.0.0-beta.3/contracts/0.8.9/WithdrawalQueue.sol

    /// @notice Request the sequence of stETH withdrawals according to passed `withdrawalRequestInputs` data
    /// @param amounts an array of stETH amount values. The standalone withdrawal request will
    ///  be created for each item in the passed list.
    /// @param _owner address that will be able to transfer or claim the request.
    ///  If `owner` is set to `address(0)`, `msg.sender` will be used as owner.
    /// @return requestIds an array of the created withdrawal requests
    function requestWithdrawals(
        // TODO: for wstETH?
        uint256[] calldata amounts,
        address _owner
    ) external returns (uint256[] memory requestIds);

    /// @notice Claim one`_requestId` request once finalized sending locked ether to the owner
    /// @param _requestId request id to claim
    /// @dev use unbounded loop to find a hint, which can lead to OOG
    /// @dev
    ///  Reverts if requestId or hint are not valid
    ///  Reverts if request is not finalized or already claimed
    ///  Reverts if msg sender is not an owner of request
    function claimWithdrawal(uint256 _requestId) external;

    /// @notice Claim a batch of withdrawal requests once finalized (claimable) sending locked ether to the owner
    /// @param _requestIds array of request ids to claim
    /// @param _hints checkpoint hint for each id.
    ///   Can be retrieved with `findCheckpointHints()`
    /// @dev
    ///  Reverts if any requestId or hint in arguments are not valid
    ///  Reverts if any request is not finalized or already claimed
    ///  Reverts if msg sender is not an owner of the requests
    function claimWithdrawals(
        uint256[] calldata _requestIds,
        uint256[] calldata _hints
    ) external;

    /// @notice Returns all withdrawal requests that belongs to the `_owner` address
    ///
    /// WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
    /// to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
    /// this function has an unbounded cost, and using it as part of a state-changing function may render the function
    /// uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
    function getWithdrawalRequests(
        address _owner
    ) external view returns (uint256[] memory requestsIds);

    /// @notice Finds the list of hints for the given `_requestIds` searching among the checkpoints with indices
    ///  in the range  `[_firstIndex, _lastIndex]`. NB! Array of request ids should be sorted
    /// @param _requestIds ids of the requests sorted in the ascending order to get hints for
    /// @param _firstIndex left boundary of the search range
    /// @param _lastIndex right boundary of the search range
    /// @return hintIds the hints for `claimWithdrawal` to find the checkpoint for the passed request ids
    function findCheckpointHints(
        uint256[] calldata _requestIds,
        uint256 _firstIndex,
        uint256 _lastIndex
    ) external view returns (uint256[] memory hintIds);

    /// @notice Returns statuses for the array of request ids
    /// @param _requestIds array of withdrawal request ids
    function getWithdrawalStatus(
        uint256[] calldata _requestIds
    ) external view returns (WithdrawalRequestStatus[] memory statuses);

    /// @notice Returns amount of ether available for claim for each provided request id
    /// @param _requestIds array of request ids
    /// @param _hints checkpoint hints. can be found with `findCheckpointHints(_requestIds, 1, getLastCheckpointIndex())`
    /// @return claimableEthValues amount of claimable ether for each request, amount is equal to 0 if request
    ///  is not finalized or already claimed
    function getClaimableEther(
        uint256[] calldata _requestIds,
        uint256[] calldata _hints
    ) external view returns (uint256[] memory claimableEthValues);
}
