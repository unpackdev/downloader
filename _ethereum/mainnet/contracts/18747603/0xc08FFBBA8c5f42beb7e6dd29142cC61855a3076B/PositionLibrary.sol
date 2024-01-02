// (c) 2023 Primex.finance
// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

import "./IERC20Metadata.sol";
import "./IAccessControl.sol";
import "./IERC165Upgradeable.sol";
import "./WadRayMath.sol";

import "./PrimexPricingLibrary.sol";
import "./TokenTransfersLibrary.sol";
import "./LimitOrderLibrary.sol";
import "./Errors.sol";

import "./Constants.sol";
import "./ITraderBalanceVault.sol";
import "./IPrimexDNS.sol";
import "./IPrimexDNSStorage.sol";
import "./IPriceOracle.sol";
import "./IBucket.sol";
import "./IConditionalClosingManager.sol";
import "./ITakeProfitStopLossCCM.sol";
import "./IKeeperRewardDistributorStorage.sol";

library PositionLibrary {
    using WadRayMath for uint256;

    event ClosePosition(
        uint256 indexed positionId,
        address indexed trader,
        address indexed closedBy,
        address bucketAddress,
        address soldAsset,
        address positionAsset,
        uint256 decreasePositionAmount,
        int256 profit,
        uint256 positionDebt,
        uint256 amountOut,
        PositionLibrary.CloseReason reason
    );

    /**
     * @notice This struct represents a trading position
     * @param id unique identifier for the position
     * @param scaledDebtAmount scaled debt amount associated with the position
     * @param bucket instance of the Bucket associated for trading
     * @param soldAsset bucket asset in the case of margin trading or deposit asset in the case of spot trading
     * @param depositAmountInSoldAsset equivalent of trader deposit size (this deposit can be in any asset) in the sold asset
     * or just deposit amount for spot trading
     * @param positionAsset asset of the trading position
     * @param positionAmount amount of the trading position
     * @param trader address of the trader holding the position
     * @param openBorrowIndex variable borrow index when position was opened
     * @param createdAt timestamp when the position was created
     * @param updatedConditionsAt timestamp when the close condition was updated
     * @param extraParams byte-encoded params, can be used for future updates
     */
    struct Position {
        uint256 id;
        uint256 scaledDebtAmount;
        IBucket bucket;
        address soldAsset;
        uint256 depositAmountInSoldAsset;
        address positionAsset;
        uint256 positionAmount;
        address trader;
        uint256 openBorrowIndex;
        uint256 createdAt;
        uint256 updatedConditionsAt;
        bytes extraParams;
    }

    struct IncreaseDepositParams {
        uint256 amount;
        address asset;
        bool takeDepositFromWallet;
        PrimexPricingLibrary.Route[] routes;
        IPrimexDNS primexDNS;
        IPriceOracle priceOracle;
        ITraderBalanceVault traderBalanceVault;
        uint256 amountOutMin;
    }

    struct DecreaseDepositParams {
        uint256 amount;
        IPrimexDNS primexDNS;
        IPriceOracle priceOracle;
        ITraderBalanceVault traderBalanceVault;
        uint256 pairPriceDrop;
        uint256 securityBuffer;
        uint256 oracleTolerableLimit;
        uint256 maintenanceBuffer;
    }

    struct MultiSwapParams {
        address tokenA;
        address tokenB;
        uint256 amountTokenA;
        PrimexPricingLibrary.Route[] routes;
        address receiver;
        uint256 deadline;
        bool takeDepositFromWallet;
        IPrimexDNS primexDNS;
        IPriceOracle priceOracle;
        ITraderBalanceVault traderBalanceVault;
    }

    struct ClosePositionParams {
        uint256 closeAmount;
        uint256 depositDecrease;
        uint256 scaledDebtAmount;
        address depositReceiver;
        PrimexPricingLibrary.Route[] routes;
        uint256 amountOutMin;
        uint256 oracleTolerableLimit;
        IPrimexDNS primexDNS;
        IPriceOracle priceOracle;
        ITraderBalanceVault traderBalanceVault;
        LimitOrderLibrary.Condition closeCondition;
        bytes ccmAdditionalParams;
        bool borrowedAmountIsNotZero;
        uint256 pairPriceDrop;
        uint256 securityBuffer;
        bool needOracleTolerableLimitCheck;
    }

    struct ClosePositionVars {
        address dexAdapter;
        uint256 borowedAssetAmount;
        uint256 amountToReturn;
        uint256 permanentLoss;
        uint256 fee;
    }

    struct ClosePositionEventData {
        int256 profit;
        uint256 debtAmount;
        uint256 amountOut;
        IKeeperRewardDistributorStorage.KeeperActionType actionType;
    }

    struct OpenPositionVars {
        PrimexPricingLibrary.Route[] firstAssetRoutes;
        PrimexPricingLibrary.Route[] depositInThirdAssetRoutes;
        PrimexPricingLibrary.DepositData depositData;
        address feeToken;
        uint256 borrowedAmount;
        uint256 amountOutMin;
        uint256 deadline;
        bool isSpot;
        bool isThirdAsset;
        bool takeDepositFromWallet;
        bool payFeeFromWallet;
        bool byOrder;
        address sender;
        LimitOrderLibrary.Condition[] closeConditions;
        bool needOracleTolerableLimitCheck;
    }

    struct OpenPositionEventData {
        uint256 protocolFee;
        uint256 entryPrice;
        uint256 leverage;
    }

    /**
     * The struct for openPosition function local vars
     */
    struct OpenPositionLocalData {
        uint256 amountToTransfer;
        address dexAdapter;
        address depositReceiver;
        uint256 depositInPositionAsset;
        bool isSpot;
    }

    /**
     * @dev Structure for the OpenPositionParams when margin trading is activated
     * @param bucket The bucket, from which the loan will be taken
     * @param borrowedAmount The amount of tokens borrowed to be exchanged
     * @param depositInThirdAssetRoutes routes to swap deposit in third asset on dex
     */
    struct OpenPositionMarginParams {
        string bucket;
        uint256 borrowedAmount;
        PrimexPricingLibrary.Route[] depositInThirdAssetRoutes;
    }

    /**
     * @dev Structure for the openPosition with parameters necessary to open a position
     * @param marginParams margin trading related params
     * @param firstAssetRoutes routes to swap first asset on dex
     * (borrowedAmount + depositAmount if deposit in borrowedAsset)
     * @param depositAsset The address of the deposit token (collateral for margin trade or
     * locked funds for spot)
     * @param depositAmount The amount of deposit funds for deal
     * @param positionAsset The address output token for exchange
     * @param amountOutMin The minimum amount of output tokens
     * that must be received for the transaction not to revert.
     * @param deadline Unix timestamp after which the transaction will revert.
     * @param takeDepositFromWallet Bool, add a deposit within the current transaction
     * @param payFeeFromWallet Bool, add a fee  within the current transaction
     * @param closeConditions Array of conditions that position can be closed by
     */
    struct OpenPositionParams {
        OpenPositionMarginParams marginParams;
        PrimexPricingLibrary.Route[] firstAssetRoutes;
        address depositAsset;
        uint256 depositAmount;
        address positionAsset;
        uint256 amountOutMin;
        uint256 deadline;
        bool takeDepositFromWallet;
        bool payFeeFromWallet;
        bool isProtocolFeeInPmx;
        LimitOrderLibrary.Condition[] closeConditions;
    }
    struct PositionManagerParams {
        IPrimexDNS primexDNS;
        IPriceOracle priceOracle;
        ITraderBalanceVault traderBalanceVault;
        uint256 oracleTolerableLimit;
        uint256 oracleTolerableLimitForThirdAsset;
        uint256 minPositionSize;
        address minPositionAsset;
        uint256 maxPositionSize;
    }

    struct ScaledParams {
        uint256 decreasePercent;
        uint256 scaledDebtAmount;
        uint256 depositDecrease;
        bool borrowedAmountIsNotZero;
    }

    enum CloseReason {
        CLOSE_BY_TRADER,
        RISKY_POSITION,
        BUCKET_DELISTED,
        LIMIT_CONDITION,
        BATCH_LIQUIDATION,
        BATCH_STOP_LOSS,
        BATCH_TAKE_PROFIT
    }

    /**
     * @dev Increases the deposit amount for a position.
     * @param position The storage reference to the position.
     * @param params The parameters for increasing the deposit.
     * @return The amount of trader debtTokens burned.
     */
    function increaseDeposit(Position storage position, IncreaseDepositParams memory params) public returns (uint256) {
        _require(msg.sender == position.trader, Errors.CALLER_IS_NOT_TRADER.selector);
        _require(position.scaledDebtAmount != 0, Errors.BORROWED_AMOUNT_IS_ZERO.selector);
        address borrowedAsset = position.soldAsset;

        uint256 depositAmountInBorrowed;
        address depositReceiver = params.primexDNS.dexAdapter();
        if (params.asset == borrowedAsset) {
            depositReceiver = address(position.bucket);
            depositAmountInBorrowed = params.amount;
        }

        if (params.takeDepositFromWallet) {
            TokenTransfersLibrary.doTransferFromTo(params.asset, msg.sender, depositReceiver, params.amount);
        } else {
            params.traderBalanceVault.useTraderAssets(
                ITraderBalanceVault.LockAssetParams(
                    msg.sender,
                    depositReceiver,
                    params.asset,
                    params.amount,
                    ITraderBalanceVault.OpenType.OPEN
                )
            );
        }

        if (params.asset != borrowedAsset) {
            depositAmountInBorrowed = PrimexPricingLibrary.multiSwap(
                PrimexPricingLibrary.MultiSwapParams({
                    tokenA: params.asset,
                    tokenB: borrowedAsset,
                    amountTokenA: params.amount,
                    routes: params.routes,
                    dexAdapter: params.primexDNS.dexAdapter(),
                    receiver: address(position.bucket),
                    deadline: block.timestamp
                }),
                0,
                address(params.primexDNS),
                address(params.priceOracle),
                false // don't need oracle check. add amountOutMin?
            );
            _require(depositAmountInBorrowed >= params.amountOutMin, Errors.SLIPPAGE_TOLERANCE_EXCEEDED.selector);
        }

        uint256 debt = getDebt(position);
        uint256 amountToTrader;
        uint256 debtToBurn = depositAmountInBorrowed;

        if (depositAmountInBorrowed >= debt) {
            amountToTrader = depositAmountInBorrowed - debt;
            debtToBurn = debt;
            position.scaledDebtAmount = 0;
            if (amountToTrader > 0)
                params.traderBalanceVault.topUpAvailableBalance(position.trader, borrowedAsset, amountToTrader);
        } else {
            position.scaledDebtAmount =
                position.scaledDebtAmount -
                debtToBurn.rdiv(position.bucket.getNormalizedVariableDebt());
        }

        position.depositAmountInSoldAsset += debtToBurn;

        position.bucket.decreaseTraderDebt(
            position.trader,
            debtToBurn,
            address(params.traderBalanceVault),
            amountToTrader,
            0
        );
        return debtToBurn;
    }

    /**
     * @dev Decreases the deposit amount for a position.
     * @param position The storage reference to the position.
     * @param params The parameters for the decrease deposit operation.
     */
    function decreaseDeposit(Position storage position, DecreaseDepositParams memory params) public {
        _require(msg.sender == position.trader, Errors.CALLER_IS_NOT_TRADER.selector);
        _require(position.bucket != IBucket(address(0)), Errors.IS_SPOT_POSITION.selector);
        _require(position.bucket.isActive(), Errors.BUCKET_IS_NOT_ACTIVE.selector);
        _require(params.amount > 0, Errors.DECREASE_AMOUNT_IS_ZERO.selector);
        _require(params.amount <= position.depositAmountInSoldAsset, Errors.AMOUNT_IS_MORE_THAN_DEPOSIT.selector);
        position.depositAmountInSoldAsset -= params.amount;
        position.scaledDebtAmount =
            position.scaledDebtAmount +
            params.amount.rdiv(position.bucket.getNormalizedVariableDebt());

        params.traderBalanceVault.topUpAvailableBalance(position.trader, position.soldAsset, params.amount);

        _require(
            health(
                position,
                params.priceOracle,
                params.pairPriceDrop,
                params.securityBuffer,
                params.oracleTolerableLimit
            ) >= WadRayMath.WAD + params.maintenanceBuffer,
            Errors.INSUFFICIENT_DEPOSIT_SIZE.selector
        );
        position.bucket.increaseDebt(position.trader, params.amount, address(params.traderBalanceVault));
    }

    /**
     * @notice Closes a position.
     * @param position The position to be closed.
     * @param params The parameters for closing the position.
     * @param reason The reason for closing the position.
     * @return posEventData The event data for the closed position.
     */
    function closePosition(
        Position memory position,
        ClosePositionParams memory params,
        CloseReason reason
    ) public returns (ClosePositionEventData memory) {
        ClosePositionEventData memory posEventData;
        ClosePositionVars memory vars;

        if (params.borrowedAmountIsNotZero) {
            posEventData.debtAmount = params.scaledDebtAmount.rmul(position.bucket.getNormalizedVariableDebt());
        }

        vars.dexAdapter = params.primexDNS.dexAdapter();
        TokenTransfersLibrary.doTransferOut(position.positionAsset, vars.dexAdapter, params.closeAmount);
        posEventData.amountOut = PrimexPricingLibrary.multiSwap(
            PrimexPricingLibrary.MultiSwapParams({
                tokenA: position.positionAsset,
                tokenB: position.soldAsset,
                amountTokenA: params.closeAmount,
                routes: params.routes,
                dexAdapter: vars.dexAdapter,
                receiver: params.borrowedAmountIsNotZero
                    ? address(position.bucket)
                    : address(params.traderBalanceVault),
                deadline: block.timestamp
            }),
            params.oracleTolerableLimit,
            address(params.primexDNS),
            address(params.priceOracle),
            params.needOracleTolerableLimitCheck
        );

        _require(
            posEventData.amountOut >= params.amountOutMin && posEventData.amountOut > 0,
            Errors.SLIPPAGE_TOLERANCE_EXCEEDED.selector
        );

        bool canBeClosed;
        if (reason == CloseReason.CLOSE_BY_TRADER) {
            canBeClosed = position.trader == msg.sender;
        } else if (reason == CloseReason.RISKY_POSITION) {
            canBeClosed =
                health(
                    position,
                    params.priceOracle,
                    params.pairPriceDrop,
                    params.securityBuffer,
                    params.oracleTolerableLimit
                ) <
                WadRayMath.WAD;
            posEventData.actionType = IKeeperRewardDistributorStorage.KeeperActionType.Liquidation;
        } else if (reason == CloseReason.LIMIT_CONDITION) {
            address cm = params.primexDNS.cmTypeToAddress(params.closeCondition.managerType);
            _require(cm != address(0), Errors.INCORRECT_CM_TYPE.selector);

            canBeClosed = IConditionalClosingManager(cm).canBeClosedAfterSwap(
                position,
                params.closeCondition.params,
                params.ccmAdditionalParams,
                params.closeAmount,
                posEventData.amountOut
            );
            posEventData.actionType = IKeeperRewardDistributorStorage.KeeperActionType.StopLoss;
        } else if (reason == CloseReason.BUCKET_DELISTED) {
            canBeClosed = position.bucket != IBucket(address(0)) && position.bucket.isDelisted();
            posEventData.actionType = IKeeperRewardDistributorStorage.KeeperActionType.BucketDelisted;
        }
        _require(canBeClosed, Errors.POSITION_CANNOT_BE_CLOSED_FOR_THIS_REASON.selector);

        uint256 permanentLoss;
        if (posEventData.amountOut > posEventData.debtAmount) {
            unchecked {
                vars.amountToReturn = posEventData.amountOut - posEventData.debtAmount;
            }
        } else {
            unchecked {
                permanentLoss = posEventData.debtAmount - posEventData.amountOut;
            }
        }

        posEventData.profit = -int256(params.depositDecrease);

        if (reason != CloseReason.RISKY_POSITION) {
            if (vars.amountToReturn > 0) {
                posEventData.profit += int256(vars.amountToReturn);
                params.traderBalanceVault.topUpAvailableBalance(
                    reason == CloseReason.CLOSE_BY_TRADER ? params.depositReceiver : position.trader,
                    position.soldAsset,
                    vars.amountToReturn
                );
            }
        }

        if (params.borrowedAmountIsNotZero) {
            position.bucket.decreaseTraderDebt(
                position.trader,
                posEventData.debtAmount,
                reason == CloseReason.RISKY_POSITION ? params.primexDNS.treasury() : address(params.traderBalanceVault),
                vars.amountToReturn,
                permanentLoss
            );
        }

        // to avoid stack to deep
        CloseReason _reason = reason;
        if (params.closeAmount == position.positionAmount) {
            emit ClosePosition({
                positionId: position.id,
                trader: position.trader,
                closedBy: msg.sender,
                bucketAddress: address(position.bucket),
                soldAsset: position.soldAsset,
                positionAsset: position.positionAsset,
                decreasePositionAmount: position.positionAmount,
                profit: posEventData.profit,
                positionDebt: posEventData.debtAmount,
                amountOut: posEventData.amountOut,
                reason: _reason
            });
        }
        return posEventData;
    }

    /**
     * @dev Sets the maximum position size between two tokens.
     * @param maxPositionSize The storage mapping for maximum position sizes.
     * @param token0 The address of token0.
     * @param token1 The address of token1.
     * @param amountInToken0 The maximum position size in token0.
     * @param amountInToken1 The maximum position size in token1.
     */
    function setMaxPositionSize(
        mapping(address => mapping(address => uint256)) storage maxPositionSize,
        address token0,
        address token1,
        uint256 amountInToken0,
        uint256 amountInToken1
    ) public {
        _require(token0 != address(0) && token1 != address(0), Errors.TOKEN_ADDRESS_IS_ZERO.selector);
        _require(token0 != token1, Errors.IDENTICAL_ASSET_ADDRESSES.selector);

        maxPositionSize[token1][token0] = amountInToken0;
        maxPositionSize[token0][token1] = amountInToken1;
    }

    /**
     * @dev Sets the tolerable limit for an oracle between two assets.
     * @param oracleTolerableLimits The mapping to store oracle tolerable limits.
     * @param assetA The address of the first asset.
     * @param assetB The address of the second asset.
     * @param percent The percentage tolerable limit for the oracle in WAD format (1 WAD = 100%).
     */
    function setOracleTolerableLimit(
        mapping(address => mapping(address => uint256)) storage oracleTolerableLimits,
        address assetA,
        address assetB,
        uint256 percent
    ) public {
        _require(assetA != address(0) && assetB != address(0), Errors.ASSET_ADDRESS_NOT_SUPPORTED.selector);
        _require(assetA != assetB, Errors.IDENTICAL_ASSET_ADDRESSES.selector);
        _require(percent <= WadRayMath.WAD && percent > 0, Errors.INVALID_PERCENT_NUMBER.selector);
        oracleTolerableLimits[assetA][assetB] = percent;
        oracleTolerableLimits[assetB][assetA] = percent;
    }

    /**
     * @dev Sets the close conditions for a given position.
     * @param position The position for which to set the close conditions.
     * @param closeConditionsMap The storage mapping of close conditions for each position ID.
     * @param closeConditions The array of close conditions to be set.
     * @param primexDNS The address of the IPrimexDNS contract.
     */
    function setCloseConditions(
        Position memory position,
        mapping(uint256 => LimitOrderLibrary.Condition[]) storage closeConditionsMap,
        LimitOrderLibrary.Condition[] memory closeConditions,
        IPrimexDNS primexDNS
    ) public {
        _require(
            LimitOrderLibrary.hasNoConditionManagerTypeDuplicates(closeConditions),
            Errors.SHOULD_NOT_HAVE_DUPLICATES.selector
        );
        if (closeConditionsMap[position.id].length > 0) {
            delete closeConditionsMap[position.id];
        }
        LimitOrderLibrary.Condition memory condition;
        for (uint256 i; i < closeConditions.length; i++) {
            condition = closeConditions[i];
            _require(
                IERC165Upgradeable(primexDNS.cmTypeToAddress(condition.managerType)).supportsInterface(
                    type(IConditionalClosingManager).interfaceId
                ),
                Errors.SHOULD_BE_CCM.selector
            );

            closeConditionsMap[position.id].push(condition);
        }
    }

    /**
     * @notice Opens a position by depositing assets and borrowing funds (except when the position is spot)
     * @param _position The position to be opened
     * @param _vars Variables related to the position opening
     * @param _pmParams Parameters for the PositionManager contract
     * @return The updated position and event data
     */
    function openPosition(
        Position memory _position,
        OpenPositionVars memory _vars,
        PositionManagerParams memory _pmParams
    ) public returns (Position memory, OpenPositionEventData memory) {
        PrimexPricingLibrary.validateMinPositionSize(
            _pmParams.minPositionSize,
            _pmParams.minPositionAsset,
            _vars.borrowedAmount + _position.depositAmountInSoldAsset,
            _position.soldAsset,
            address(_pmParams.priceOracle)
        );
        OpenPositionLocalData memory data;
        data.amountToTransfer = _vars.borrowedAmount;
        data.dexAdapter = _pmParams.primexDNS.dexAdapter();
        data.depositReceiver = data.dexAdapter;
        if (_vars.depositData.depositAsset == _position.positionAsset) {
            _position.positionAmount = _vars.depositData.depositAmount;
            data.depositInPositionAsset = _vars.depositData.depositAmount;
            data.depositReceiver = address(this);
        } else if (_vars.depositData.depositAsset == _position.soldAsset) {
            data.amountToTransfer += _vars.depositData.depositAmount;
        }

        data.isSpot = _vars.borrowedAmount == 0;
        if (data.isSpot) _vars.depositData.depositAsset = _position.soldAsset;

        if (_vars.takeDepositFromWallet) {
            TokenTransfersLibrary.doTransferFromTo(
                _vars.depositData.depositAsset,
                msg.sender,
                data.depositReceiver,
                _vars.depositData.depositAmount
            );
        } else {
            _pmParams.traderBalanceVault.useTraderAssets(
                ITraderBalanceVault.LockAssetParams({
                    trader: _position.trader,
                    depositReceiver: data.depositReceiver,
                    depositAsset: _vars.depositData.depositAsset,
                    depositAmount: _vars.depositData.depositAmount,
                    openType: _vars.byOrder
                        ? ITraderBalanceVault.OpenType.OPEN_BY_ORDER
                        : ITraderBalanceVault.OpenType.OPEN
                })
            );
        }

        if (!data.isSpot) {
            _position.bucket.increaseDebt(_position.trader, _vars.borrowedAmount, data.dexAdapter);
            // @note You need to write index only after opening a position in bucket.
            // Since when opening position in the bucket, index becomes relevant (containing accumulated profit)
            _position.openBorrowIndex = _position.bucket.variableBorrowIndex();
            _position.scaledDebtAmount = _vars.borrowedAmount.rdiv(_position.openBorrowIndex);
        }
        if (_vars.isThirdAsset) {
            data.depositInPositionAsset = PrimexPricingLibrary.multiSwap(
                PrimexPricingLibrary.MultiSwapParams({
                    tokenA: _vars.depositData.depositAsset,
                    tokenB: _position.positionAsset,
                    amountTokenA: _vars.depositData.depositAmount,
                    routes: _vars.depositInThirdAssetRoutes,
                    dexAdapter: data.dexAdapter,
                    receiver: address(this),
                    deadline: _vars.deadline
                }),
                _pmParams.oracleTolerableLimitForThirdAsset,
                address(_pmParams.primexDNS),
                address(_pmParams.priceOracle),
                true
            );
            _position.positionAmount += data.depositInPositionAsset;
        } else {
            _require(
                _vars.depositInThirdAssetRoutes.length == 0,
                Errors.DEPOSIT_IN_THIRD_ASSET_ROUTES_LENGTH_SHOULD_BE_0.selector
            );
        }

        uint256 borrowedAmountInPositionAsset = PrimexPricingLibrary.multiSwap(
            PrimexPricingLibrary.MultiSwapParams({
                tokenA: _position.soldAsset,
                tokenB: _position.positionAsset,
                amountTokenA: data.isSpot ? _vars.depositData.depositAmount : data.amountToTransfer,
                routes: _vars.firstAssetRoutes,
                dexAdapter: data.dexAdapter,
                receiver: address(this),
                deadline: _vars.deadline
            }),
            _pmParams.oracleTolerableLimit,
            address(_pmParams.primexDNS),
            address(_pmParams.priceOracle),
            _vars.needOracleTolerableLimitCheck
        );
        _position.positionAmount += borrowedAmountInPositionAsset;
        _require(_pmParams.maxPositionSize >= _position.positionAmount, Errors.POSITION_SIZE_EXCEEDED.selector);
        uint256 leverage = WadRayMath.WAD;
        if (!data.isSpot) {
            if (_vars.depositData.depositAsset == _position.soldAsset) {
                leverage = (_vars.borrowedAmount + _position.depositAmountInSoldAsset).wdiv(
                    _position.depositAmountInSoldAsset
                );
            } else {
                leverage = (borrowedAmountInPositionAsset + data.depositInPositionAsset).wdiv(
                    data.depositInPositionAsset
                );
            }
            _require(
                leverage <= _position.bucket.maxAssetLeverage(_position.positionAsset),
                Errors.INSUFFICIENT_DEPOSIT.selector
            );
        }

        if (!_vars.byOrder) {
            _vars.depositData.leverage = leverage;
        }

        _require(_position.positionAmount >= _vars.amountOutMin, Errors.SLIPPAGE_TOLERANCE_EXCEEDED.selector);

        OpenPositionEventData memory posEventData;

        posEventData.protocolFee = PrimexPricingLibrary.payProtocolFee(
            PrimexPricingLibrary.ProtocolFeeParams({
                depositData: _vars.depositData,
                feeToken: _vars.feeToken,
                isSwapFromWallet: _vars.payFeeFromWallet,
                calculateFee: !_vars.byOrder,
                orderType: _vars.byOrder
                    ? IPrimexDNSStorage.OrderType.LIMIT_ORDER
                    : IPrimexDNSStorage.OrderType.MARKET_ORDER,
                trader: _position.trader,
                priceOracle: address(_pmParams.priceOracle),
                traderBalanceVault: _pmParams.traderBalanceVault,
                primexDNS: _pmParams.primexDNS
            })
        );

        uint256 multiplierBorrowedAsset = 10 ** (18 - IERC20Metadata(_position.soldAsset).decimals());
        uint256 multiplierPositionAsset = 10 ** (18 - IERC20Metadata(_position.positionAsset).decimals());
        posEventData.entryPrice =
            ((_vars.borrowedAmount + _position.depositAmountInSoldAsset) * multiplierBorrowedAsset).wdiv(
                _position.positionAmount * multiplierPositionAsset
            ) /
            multiplierBorrowedAsset;
        posEventData.leverage = _vars.depositData.leverage;
        return (_position, posEventData);
    }

    /**
     * @dev Retrieves the debt amount for a given position.
     * @param position The Position struct representing the position to get the debt amount for.
     * @return The debt amount in debtTokens.
     */
    function getDebt(Position memory position) public view returns (uint256) {
        if (position.scaledDebtAmount == 0) return 0;
        return position.scaledDebtAmount.rmul(position.bucket.getNormalizedVariableDebt());
    }

    /**
     * @dev Calculates the health of a position.
     * @dev health = ((1 - securityBuffer) * (1 - oracleTolerableLimit) * (1 - priceDrop) * borrowedAssetAmountOut) /
     (feeBuffer * debt)
     * @param position The position object containing relevant information.
     * @param priceOracle The price oracle contract used for obtaining asset prices.
     * @param pairPriceDrop The priceDrop in WAD format of the asset pair.
     * @param securityBuffer The security buffer in WAD format for the position.
     * @param oracleTolerableLimit The tolerable limit in WAD format for the price oracle.
     * @return The health value in WAD format of the position.
     */
    function health(
        Position memory position,
        IPriceOracle priceOracle,
        uint256 pairPriceDrop,
        uint256 securityBuffer,
        uint256 oracleTolerableLimit
    ) public view returns (uint256) {
        if (position.scaledDebtAmount == 0) return WadRayMath.WAD;
        return
            health(
                PrimexPricingLibrary.getOracleAmountsOut(
                    position.positionAsset,
                    position.soldAsset,
                    position.positionAmount,
                    address(priceOracle)
                ),
                pairPriceDrop,
                securityBuffer,
                oracleTolerableLimit,
                getDebt(position),
                position.bucket.feeBuffer()
            );
    }

    /**
     * @dev Creates a new position based on the given parameters.
     * @param _params The input parameters for creating the position.
     * @param primexDNS The address of the PrimexDNS contract.
     * @param priceOracle The address of the PriceOracle contract.
     * @return position The created Position struct.
     * @return vars The OpenPositionVars struct.
     */
    function createPosition(
        OpenPositionParams calldata _params,
        IPrimexDNS primexDNS,
        IPriceOracle priceOracle
    ) public view returns (Position memory, OpenPositionVars memory) {
        OpenPositionVars memory vars = OpenPositionVars({
            firstAssetRoutes: _params.firstAssetRoutes,
            depositInThirdAssetRoutes: _params.marginParams.depositInThirdAssetRoutes,
            depositData: PrimexPricingLibrary.DepositData({
                protocolFee: 0,
                depositAsset: address(0),
                depositAmount: _params.depositAmount,
                leverage: 0
            }),
            feeToken: _params.isProtocolFeeInPmx ? primexDNS.pmx() : NATIVE_CURRENCY,
            borrowedAmount: _params.marginParams.borrowedAmount,
            amountOutMin: _params.amountOutMin,
            deadline: _params.deadline,
            isSpot: _params.marginParams.borrowedAmount == 0,
            isThirdAsset: false,
            takeDepositFromWallet: _params.takeDepositFromWallet,
            payFeeFromWallet: _params.payFeeFromWallet,
            byOrder: false,
            sender: address(0),
            closeConditions: _params.closeConditions,
            needOracleTolerableLimitCheck: _params.marginParams.borrowedAmount > 0
        });
        PositionLibrary.Position memory position = PositionLibrary.Position({
            id: 0,
            scaledDebtAmount: 0,
            bucket: IBucket(address(0)),
            soldAsset: address(0),
            depositAmountInSoldAsset: 0,
            positionAsset: _params.positionAsset,
            positionAmount: 0,
            trader: msg.sender,
            openBorrowIndex: 0,
            createdAt: block.timestamp,
            updatedConditionsAt: block.timestamp,
            extraParams: ""
        });

        if (vars.isSpot) {
            _require(_params.depositAsset != _params.positionAsset, Errors.SHOULD_BE_DIFFERENT_ASSETS_IN_SPOT.selector);
            _require(bytes(_params.marginParams.bucket).length == 0, Errors.BUCKET_SHOULD_BE_UNDEFINED.selector);
            priceOracle.getPriceFeedsPair(_params.positionAsset, _params.depositAsset);
            position.soldAsset = _params.depositAsset;
            position.depositAmountInSoldAsset = vars.depositData.depositAmount;
            vars.depositData.leverage = WadRayMath.WAD;
        } else {
            position.bucket = IBucket(primexDNS.getBucketAddress(_params.marginParams.bucket));
            position.soldAsset = address(position.bucket.borrowedAsset());
            vars.depositData.depositAsset = _params.depositAsset;
            (, bool tokenAllowed) = position.bucket.allowedAssets(_params.positionAsset);
            _require(tokenAllowed, Errors.TOKEN_NOT_SUPPORTED.selector);

            vars.isThirdAsset =
                _params.depositAsset != position.soldAsset &&
                _params.depositAsset != _params.positionAsset;

            position.depositAmountInSoldAsset = PrimexPricingLibrary.getOracleAmountsOut(
                _params.depositAsset,
                position.soldAsset,
                _params.depositAmount,
                address(priceOracle)
            );
        }

        return (position, vars);
    }

    /**
     * @notice Creates a position based on the provided order parameters.
     * @dev This function calculates and returns a Position and OpenPositionVars struct.
     * @param _params The OpenPositionByOrderParams struct containing the order parameters.
     * @param priceOracle The price oracle contract used for retrieving asset prices.
     * @return position The Position struct representing the created position.
     * @return vars The OpenPositionVars struct containing additional variables related to the position.
     */
    function createPositionByOrder(
        LimitOrderLibrary.OpenPositionByOrderParams calldata _params,
        IPriceOracle priceOracle
    ) public view returns (Position memory, OpenPositionVars memory) {
        OpenPositionVars memory vars = OpenPositionVars({
            firstAssetRoutes: _params.firstAssetRoutes,
            depositInThirdAssetRoutes: _params.depositInThirdAssetRoutes,
            depositData: PrimexPricingLibrary.DepositData({
                protocolFee: _params.order.protocolFee,
                depositAsset: address(0),
                depositAmount: _params.order.depositAmount,
                leverage: _params.order.leverage
            }),
            feeToken: _params.order.feeToken,
            borrowedAmount: 0,
            amountOutMin: 0,
            deadline: _params.order.deadline,
            isSpot: _params.order.leverage == WadRayMath.WAD,
            isThirdAsset: false,
            takeDepositFromWallet: false,
            payFeeFromWallet: false,
            byOrder: true,
            sender: _params.sender,
            closeConditions: _params.closeConditions,
            needOracleTolerableLimitCheck: true
        });

        Position memory position = Position({
            id: 0,
            scaledDebtAmount: 0,
            bucket: IBucket(address(0)),
            soldAsset: address(0),
            depositAmountInSoldAsset: 0,
            positionAsset: _params.order.positionAsset,
            positionAmount: 0,
            trader: _params.order.trader,
            openBorrowIndex: 0,
            createdAt: block.timestamp,
            updatedConditionsAt: block.timestamp,
            extraParams: ""
        });

        if (vars.isSpot) {
            position.soldAsset = _params.order.depositAsset;
            position.depositAmountInSoldAsset = vars.depositData.depositAmount;
        } else {
            position.bucket = _params.order.bucket;
            position.soldAsset = address(position.bucket.borrowedAsset());
            vars.depositData.depositAsset = _params.order.depositAsset;
            vars.isThirdAsset =
                _params.order.depositAsset != position.soldAsset &&
                _params.order.depositAsset != _params.order.positionAsset;

            position.depositAmountInSoldAsset = PrimexPricingLibrary.getOracleAmountsOut(
                _params.order.depositAsset,
                position.soldAsset,
                _params.order.depositAmount,
                address(priceOracle)
            );
            vars.borrowedAmount = position.depositAmountInSoldAsset.wmul(_params.order.leverage - WadRayMath.WAD);
        }
        return (position, vars);
    }

    /**
     * @notice Calculates the health score for a position.
     * @param borrowedAssetAmountOut The amount of borrowed assets.
     * @param pairPriceDrop The priceDrop in WAD format of the pair.
     * @param securityBuffer The security buffer in WAD format.
     * @param oracleTolerableLimit The tolerable limit in WAD format for the oracle.
     * @param positionDebt The debt of the position.
     * @param feeBuffer The buffer for fees.
     * @return The health score of the position.
     */
    function health(
        uint256 borrowedAssetAmountOut,
        uint256 pairPriceDrop,
        uint256 securityBuffer,
        uint256 oracleTolerableLimit,
        uint256 positionDebt,
        uint256 feeBuffer
    ) public pure returns (uint256) {
        return
            (
                (WadRayMath.WAD - securityBuffer)
                    .wmul(WadRayMath.WAD - oracleTolerableLimit)
                    .wmul(WadRayMath.WAD - pairPriceDrop)
                    .wmul(borrowedAssetAmountOut)
            ).wdiv(feeBuffer.wmul(positionDebt));
    }
}
