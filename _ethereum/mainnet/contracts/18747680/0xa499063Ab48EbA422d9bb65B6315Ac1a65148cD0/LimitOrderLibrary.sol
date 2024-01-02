// (c) 2023 Primex.finance
// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

import "./IERC20Metadata.sol";
import "./IAccessControl.sol";
import "./IERC165Upgradeable.sol";
import "./WadRayMath.sol";

import "./PrimexPricingLibrary.sol";
import "./TokenTransfersLibrary.sol";

import "./Constants.sol";
import "./ITraderBalanceVault.sol";
import "./IPrimexDNS.sol";
import "./IPrimexDNSStorage.sol";
import "./IPriceOracle.sol";
import "./IBucket.sol";
import "./IConditionalOpeningManager.sol";
import "./IConditionalClosingManager.sol";
import "./IPositionManager.sol";
import "./ISwapManager.sol";

import "./Errors.sol";

library LimitOrderLibrary {
    using WadRayMath for uint256;

    enum CloseReason {
        FilledMargin,
        FilledSpot,
        FilledSwap,
        Cancelled
    }

    struct Condition {
        uint256 managerType;
        bytes params;
    }

    /**
     * @dev Creates a limit order and locks the deposit asset in the traderBalanceVault
     * @param bucket The bucket, from which the loan will be taken
     * @param positionAsset The address of output token for exchange
     * @param depositAsset The address of the deposit token
     * @param depositAmount The amount of deposit trader funds for deal
     * @param feeToken An asset in which the fee will be paid. At this point it could be the pmx, the epmx or a native currency
     * @param trader The trader, who has created the order
     * @param deadline Unix timestamp after which the order will not be filled
     * @param id The unique id of the order
     * @param leverage leverage for trading
     * @param shouldOpenPosition The flag to indicate whether position should be opened
     * @param createdAt The timeStamp when the order was created
     * @param updatedConditionsAt The timestamp when the open condition was updated
     */
    struct LimitOrder {
        IBucket bucket;
        address positionAsset;
        address depositAsset;
        uint256 depositAmount;
        address feeToken;
        uint256 protocolFee;
        address trader;
        uint256 deadline;
        uint256 id;
        uint256 leverage;
        bool shouldOpenPosition;
        uint256 createdAt;
        uint256 updatedConditionsAt;
        // The byte-encoded params, can be used for future updates
        bytes extraParams;
    }

    /**
     * @dev Structure for the сreateLimitOrder with parameters necessary to create limit order
     * @param bucket The bucket, from which the loan will be taken
     * @param depositAsset The address of the deposit token (collateral for margin trade or
     * locked funds for spot)
     * @param depositAmount The amount of deposit funds for deal
     * @param positionAsset The address output token for exchange
     * @param deadline Unix timestamp after which the order will not be filled
     * @param takeDepositFromWallet Bool, add a collateral deposit within the current transaction
     * @param leverage leverage for trading
     * @param shouldOpenPosition Bool, indicate whether position should be opened
     * @param openingManagerAddresses Array of contract addresses that will be called in canBeFilled
     * @param openingManagerParams Array of bytes representing params for contracts in openingManagerAddresses
     * @param closingManagerAddresses Array of contract addresses that will be called in canBeClosed
     * @param closingManagerParams Array of bytes representing params for contracts in closingManagerAddresses
     */
    struct CreateLimitOrderParams {
        string bucket;
        uint256 depositAmount;
        address depositAsset;
        address positionAsset;
        uint256 deadline;
        bool takeDepositFromWallet;
        bool payFeeFromWallet;
        uint256 leverage;
        bool shouldOpenPosition;
        Condition[] openConditions;
        Condition[] closeConditions;
        bool isProtocolFeeInPmx;
    }

    struct CreateLimitOrderVars {
        bool isSpot;
        IBucket bucket;
        uint256 positionSize;
        address priceOracle;
        uint256 rate;
        address feeToken;
    }

    /**
     * @dev Opens a position on an existing order
     * @param orderId order id
     * @param com address of ConditionalOpeningManager
     * @param comAdditionalParams  params needed for ConditionalOpeningManager to calc canBeFilled
     * @param firstAssetRoutes routes to swap first asset
     * @param depositInThirdAssetRoutes routes to swap deposit asset
     */
    struct OpenPositionParams {
        uint256 orderId;
        uint256 conditionIndex;
        bytes comAdditionalParams;
        PrimexPricingLibrary.Route[] firstAssetRoutes;
        PrimexPricingLibrary.Route[] depositInThirdAssetRoutes;
        address keeper;
    }

    struct OpenPositionByOrderVars {
        address assetIn;
        address assetOut;
        uint256 amountIn;
        uint256 amountOut;
        CloseReason closeReason;
        uint256 newPositionId;
        uint256 exchangeRate;
    }

    /**
     * @dev Params for PositionManager to open position
     * @param order order
     * @param firstAssetRoutes routes to swap first asset on dex
     * (borrowedAmount + depositAmount if deposit in borrowedAsset)
     * @param depositInThirdAssetRoutes routes to swap deposit in third asset on dex
     */
    struct OpenPositionByOrderParams {
        address sender;
        LimitOrder order;
        Condition[] closeConditions;
        PrimexPricingLibrary.Route[] firstAssetRoutes;
        PrimexPricingLibrary.Route[] depositInThirdAssetRoutes;
    }

    /**
     * @dev Structure for the updateOrder with parameters necessary to update limit order
     * @param orderId order id to update
     * @param depositAmount The amount of deposit funds for deal
     * @param makeDeposit Bool, add a collateral deposit within the current transaction
     * @param leverage leverage for trading
     * @param takeDepositFromWallet Bool, add a collateral deposit within the current transaction
     * @param payFeeFromWallet A flag indicating whether the Limit Order fee is perfomed from a wallet or a protocol balance.
     */
    struct UpdateLimitOrderParams {
        uint256 orderId;
        uint256 depositAmount;
        uint256 leverage;
        bool isProtocolFeeInPmx;
        bool takeDepositFromWallet;
        bool payFeeFromWallet;
    }

    /**
     * @notice Updates the protocol fee for a LimitOrder.
     * @param _order The LimitOrder storage object to update.
     * @param _params The new parameters for the LimitOrder.
     * @param _traderBalanceVault The instance of the TraderBalanceVault contract.
     * @param _primexDNS The PrimexDNS contract for accessing PMX-related information.
     * @param _priceOracle The address of the price oracle contract.
     */
    function updateProtocolFee(
        LimitOrder storage _order,
        UpdateLimitOrderParams calldata _params,
        ITraderBalanceVault _traderBalanceVault,
        IPrimexDNS _primexDNS,
        address _priceOracle
    ) public {
        address feeToken;
        if (_params.isProtocolFeeInPmx) {
            feeToken = _primexDNS.pmx();
            _require(msg.value == 0, Errors.DISABLED_TRANSFER_NATIVE_CURRENCY.selector);
        } else {
            feeToken = NATIVE_CURRENCY;
        }
        if (
            _params.leverage != _order.leverage ||
            _params.depositAmount != _order.depositAmount ||
            feeToken != _order.feeToken
        ) {
            uint256 newProtocolFee = PrimexPricingLibrary.calculateProtocolFee(
                PrimexPricingLibrary.DepositData({
                    protocolFee: 0,
                    depositAsset: _order.depositAsset,
                    depositAmount: _params.depositAmount,
                    leverage: _params.leverage
                }),
                _primexDNS,
                _priceOracle,
                _order.shouldOpenPosition
                    ? IPrimexDNSStorage.OrderType.LIMIT_ORDER
                    : IPrimexDNSStorage.OrderType.SWAP_LIMIT_ORDER,
                feeToken
            );
            if (feeToken == _order.feeToken) {
                uint256 amount;
                unchecked {
                    if (newProtocolFee > _order.protocolFee) amount = newProtocolFee - _order.protocolFee;
                    else amount = _order.protocolFee - newProtocolFee;
                }
                depositLockOrUnlock(
                    _traderBalanceVault,
                    feeToken,
                    amount,
                    _params.payFeeFromWallet,
                    newProtocolFee > _order.protocolFee
                );
            } else {
                if (newProtocolFee > 0) {
                    //lock the new fee token
                    depositLockOrUnlock(_traderBalanceVault, feeToken, newProtocolFee, _params.payFeeFromWallet, true);
                }
                //unlock the old fee token
                depositLockOrUnlock(
                    _traderBalanceVault,
                    _order.feeToken,
                    _order.protocolFee,
                    _params.payFeeFromWallet,
                    false
                );
                _order.feeToken = feeToken;
            }
            _order.protocolFee = newProtocolFee;
        }
    }

    /**
     * @notice Updates the leverage of a limit order.
     * @param _order The limit order to update.
     * @param _leverage The new leverage value in WAD format for the order.
     */
    function updateLeverage(LimitOrder storage _order, uint256 _leverage) public {
        _require(_leverage > WadRayMath.WAD, Errors.LEVERAGE_MUST_BE_MORE_THAN_1.selector);
        _require(_order.leverage != WadRayMath.WAD, Errors.CANNOT_CHANGE_SPOT_ORDER_TO_MARGIN.selector);

        _require(
            _leverage < _order.bucket.maxAssetLeverage(_order.positionAsset),
            Errors.LEVERAGE_EXCEEDS_MAX_LEVERAGE.selector
        );
        _order.leverage = _leverage;
    }

    /**
     * @notice Updates the deposit details of a LimitOrder.
     * @param _order The LimitOrder to update.
     * @param _amount The amount of the asset being deposited.
     * @param _takeDepositFromWallet Boolean indicating whether to make a deposit or unlock the deposited asset.
     * @param traderBalanceVault The instance of ITraderBalanceVault used for deposit and unlock operations.
     */
    function updateDeposit(
        LimitOrderLibrary.LimitOrder storage _order,
        uint256 _amount,
        bool _takeDepositFromWallet,
        ITraderBalanceVault traderBalanceVault
    ) public {
        depositLockOrUnlock(
            traderBalanceVault,
            _order.depositAsset,
            (_amount > _order.depositAmount) ? _amount - _order.depositAmount : _order.depositAmount - _amount,
            _takeDepositFromWallet,
            _amount > _order.depositAmount
        );
        _order.depositAmount = _amount;
    }

    /**
     * @notice Sets the open conditions for a LimitOrder.
     * @param _order The limit order.
     * @param openConditionsMap The mapping of order IDs to open conditions.
     * @param openConditions The array of open conditions.
     * @param primexDNS The instance of the Primex DNS contract.
     */
    function setOpenConditions(
        LimitOrderLibrary.LimitOrder memory _order,
        mapping(uint256 => Condition[]) storage openConditionsMap,
        Condition[] memory openConditions,
        IPrimexDNS primexDNS
    ) public {
        _require(hasNoConditionManagerTypeDuplicates(openConditions), Errors.SHOULD_NOT_HAVE_DUPLICATES.selector);
        _require(openConditions.length > 0, Errors.SHOULD_HAVE_OPEN_CONDITIONS.selector);
        if (openConditionsMap[_order.id].length > 0) {
            delete openConditionsMap[_order.id];
        }
        Condition memory condition;
        for (uint256 i; i < openConditions.length; i++) {
            condition = openConditions[i];
            _require(
                IERC165Upgradeable(primexDNS.cmTypeToAddress(condition.managerType)).supportsInterface(
                    type(IConditionalOpeningManager).interfaceId
                ),
                Errors.SHOULD_BE_COM.selector
            );
            openConditionsMap[_order.id].push(condition);
        }
    }

    /**
     * @notice Sets the close conditions for a LimitOrder.
     * @param _order The limit order.
     * @param closeConditionsMap The mapping of order IDs to close conditions.
     * @param closeConditions The array of close conditions to set.
     * @param primexDNS The Primex DNS contract address.
     */
    function setCloseConditions(
        LimitOrderLibrary.LimitOrder memory _order,
        mapping(uint256 => Condition[]) storage closeConditionsMap,
        Condition[] memory closeConditions,
        IPrimexDNS primexDNS
    ) public {
        _require(hasNoConditionManagerTypeDuplicates(closeConditions), Errors.SHOULD_NOT_HAVE_DUPLICATES.selector);
        _require(
            _order.shouldOpenPosition || closeConditions.length == 0,
            Errors.SHOULD_NOT_HAVE_CLOSE_CONDITIONS.selector
        );

        if (closeConditionsMap[_order.id].length > 0) {
            delete closeConditionsMap[_order.id];
        }
        Condition memory condition;
        for (uint256 i; i < closeConditions.length; i++) {
            condition = closeConditions[i];
            _require(
                IERC165Upgradeable(primexDNS.cmTypeToAddress(condition.managerType)).supportsInterface(
                    type(IConditionalClosingManager).interfaceId
                ),
                Errors.SHOULD_BE_CCM.selector
            );
            closeConditionsMap[_order.id].push(condition);
        }
    }

    /**
     * @notice Creates a limit order.
     * @param _params The struct containing the order parameters.
     * @param pm The instance of the PositionManager contract.
     * @param traderBalanceVault The instance of the TraderBalanceVault contract.
     * @param primexDNS The instance of the PrimexDNS contract.
     * @return The created limit order.
     */
    function createLimitOrder(
        CreateLimitOrderParams calldata _params,
        IPositionManager pm,
        ITraderBalanceVault traderBalanceVault,
        IPrimexDNS primexDNS
    ) public returns (LimitOrder memory) {
        _require(_params.leverage >= WadRayMath.WAD, Errors.INCORRECT_LEVERAGE.selector);
        _require(_params.deadline > block.timestamp, Errors.INCORRECT_DEADLINE.selector);

        CreateLimitOrderVars memory vars;
        vars.isSpot = bytes(_params.bucket).length == 0;
        vars.positionSize = _params.depositAmount.wmul(_params.leverage);
        vars.priceOracle = address(pm.priceOracle());
        if (vars.isSpot) {
            _require(_params.leverage == WadRayMath.WAD, Errors.LEVERAGE_SHOULD_BE_1.selector);
            _require(_params.depositAsset != _params.positionAsset, Errors.SHOULD_BE_DIFFERENT_ASSETS_IN_SPOT.selector);
            IPriceOracle(vars.priceOracle).getPriceFeedsPair(_params.positionAsset, _params.depositAsset);
        } else {
            _require(_params.shouldOpenPosition, Errors.SHOULD_OPEN_POSITION.selector);
            _require(_params.leverage > WadRayMath.WAD, Errors.LEVERAGE_MUST_BE_MORE_THAN_1.selector);
            vars.bucket = IBucket(primexDNS.getBucketAddress(_params.bucket));
            _require(vars.bucket.getLiquidityMiningParams().isBucketLaunched, Errors.BUCKET_IS_NOT_LAUNCHED.selector);

            (, bool tokenAllowed) = vars.bucket.allowedAssets(_params.positionAsset);
            _require(tokenAllowed, Errors.TOKEN_NOT_SUPPORTED.selector);
            _require(
                _params.leverage < vars.bucket.maxAssetLeverage(_params.positionAsset),
                Errors.LEVERAGE_EXCEEDS_MAX_LEVERAGE.selector
            );
        }
        LimitOrder memory order = LimitOrder({
            bucket: IBucket(address(0)),
            positionAsset: _params.positionAsset,
            depositAsset: _params.depositAsset,
            depositAmount: _params.depositAmount,
            feeToken: _params.isProtocolFeeInPmx ? primexDNS.pmx() : NATIVE_CURRENCY,
            protocolFee: 0,
            trader: msg.sender,
            deadline: _params.deadline,
            id: 0,
            leverage: _params.leverage,
            shouldOpenPosition: _params.shouldOpenPosition,
            createdAt: block.timestamp,
            updatedConditionsAt: block.timestamp,
            extraParams: ""
        });
        order.bucket = vars.bucket;

        PrimexPricingLibrary.validateMinPositionSize(
            pm.minPositionSize(),
            pm.minPositionAsset(),
            vars.positionSize,
            order.depositAsset,
            vars.priceOracle
        );
        if (_params.isProtocolFeeInPmx) {
            vars.feeToken = primexDNS.pmx();
            _require(msg.value == 0, Errors.DISABLED_TRANSFER_NATIVE_CURRENCY.selector);
        } else {
            vars.feeToken = NATIVE_CURRENCY;
        }

        order.protocolFee = PrimexPricingLibrary.calculateProtocolFee(
            PrimexPricingLibrary.DepositData({
                protocolFee: 0,
                depositAsset: _params.depositAsset,
                depositAmount: _params.depositAmount,
                leverage: _params.leverage
            }),
            primexDNS,
            vars.priceOracle,
            order.shouldOpenPosition
                ? IPrimexDNSStorage.OrderType.LIMIT_ORDER
                : IPrimexDNSStorage.OrderType.SWAP_LIMIT_ORDER,
            vars.feeToken
        );

        if (order.protocolFee > 0) {
            // fee locking
            depositLockOrUnlock(traderBalanceVault, vars.feeToken, order.protocolFee, _params.payFeeFromWallet, true);
        }
        // deposit locking
        depositLockOrUnlock(
            traderBalanceVault,
            order.depositAsset,
            order.depositAmount,
            _params.takeDepositFromWallet,
            true
        );

        return order;
    }

    /**
     * @notice Opens a position by order.
     * @param order The LimitOrder storage containing order details.
     * @param _params The OpenPositionParams calldata containing additional position parameters.
     * @param _closeConditions The Condition array containing close conditions for the position.
     * @param pm The instance of the PositionManager contract.
     * @param traderBalanceVault The instance of the TraderBalanceVault contract.
     * @param primexDNS The instance of the PrimexDNS contract.
     * @param swapManager The instance of the SwapManager contract.
     * @return vars The OpenPositionByOrderVars struct containing the result of the open position operation.
     */
    function openPositionByOrder(
        LimitOrder storage order,
        OpenPositionParams calldata _params,
        Condition[] memory _closeConditions,
        IPositionManager pm,
        ITraderBalanceVault traderBalanceVault,
        IPrimexDNS primexDNS,
        ISwapManager swapManager
    ) public returns (OpenPositionByOrderVars memory) {
        OpenPositionByOrderVars memory vars;
        bool isSpot = address(order.bucket) == address(0);

        if (order.shouldOpenPosition) {
            vars.closeReason = isSpot ? CloseReason.FilledSpot : CloseReason.FilledMargin;
            (vars.amountIn, vars.amountOut, vars.newPositionId, vars.exchangeRate) = pm.openPositionByOrder(
                OpenPositionByOrderParams({
                    sender: msg.sender,
                    order: order,
                    closeConditions: _closeConditions,
                    firstAssetRoutes: _params.firstAssetRoutes,
                    depositInThirdAssetRoutes: _params.depositInThirdAssetRoutes
                })
            );
        } else {
            _require(
                _params.depositInThirdAssetRoutes.length == 0,
                Errors.DEPOSIT_IN_THIRD_ASSET_ROUTES_LENGTH_SHOULD_BE_0.selector
            );
            vars.closeReason = CloseReason.FilledSwap;
            vars.amountIn = order.depositAmount;

            // calculateFee is false so 'depositData' and 'priceOracle' are default values except 'protocolFee'
            PrimexPricingLibrary.payProtocolFee(
                PrimexPricingLibrary.ProtocolFeeParams({
                    depositData: PrimexPricingLibrary.DepositData({
                        protocolFee: order.protocolFee,
                        depositAsset: address(0),
                        depositAmount: 0,
                        leverage: 0
                    }),
                    feeToken: order.feeToken,
                    isSwapFromWallet: false,
                    calculateFee: false,
                    orderType: IPrimexDNSStorage.OrderType.SWAP_LIMIT_ORDER,
                    trader: order.trader,
                    priceOracle: address(0),
                    traderBalanceVault: traderBalanceVault,
                    primexDNS: primexDNS
                })
            );

            traderBalanceVault.unlockAsset(
                ITraderBalanceVault.UnlockAssetParams({
                    trader: order.trader,
                    receiver: address(this),
                    asset: order.depositAsset,
                    amount: order.depositAmount
                })
            );

            vars.amountOut = swapManager.swap(
                ISwapManager.SwapParams({
                    tokenA: order.depositAsset,
                    tokenB: order.positionAsset,
                    amountTokenA: order.depositAmount,
                    amountOutMin: 0,
                    routes: _params.firstAssetRoutes,
                    receiver: order.trader,
                    deadline: order.deadline,
                    isSwapFromWallet: false,
                    isSwapToWallet: false,
                    isSwapFeeInPmx: false,
                    payFeeFromWallet: false
                }),
                pm.getOracleTolerableLimit(order.depositAsset, order.positionAsset),
                true
            );
            uint256 multiplierDepositAsset = 10 ** (18 - IERC20Metadata(order.depositAsset).decimals());
            uint256 multiplierPositionAsset = 10 ** (18 - IERC20Metadata(order.positionAsset).decimals());
            vars.exchangeRate =
                (vars.amountIn * multiplierDepositAsset).wdiv(vars.amountOut * multiplierPositionAsset) /
                multiplierDepositAsset;
        }

        vars.assetIn = isSpot ? order.depositAsset : address(order.bucket.borrowedAsset());
        vars.assetOut = order.positionAsset;
        return vars;
    }

    /**
     * @notice Checks if an array of Condition structs has no duplicate manager types.
     * @param conditions The array of Condition structs to be checked.
     * @return bool Boolean value indicating whether the array has no duplicate manager types.
     */
    function hasNoConditionManagerTypeDuplicates(Condition[] memory conditions) public pure returns (bool) {
        if (conditions.length == 0) {
            return true;
        }
        for (uint256 i; i < conditions.length - 1; i++) {
            for (uint256 j = i + 1; j < conditions.length; j++) {
                if (conditions[i].managerType == conditions[j].managerType) {
                    return false;
                }
            }
        }
        return true;
    }

    /**
     * @notice This function is used to either deposit or unlock assets in the trader balance vault.
     * @param traderBalanceVault The instance of the trader balance vault.
     * @param _depositAsset The address of the asset to be deposited or unlocked.
     * @param _amount The amount of the asset to be deposited or unlocked.
     * @param _takeDepositFromWallet Boolean indicating whether to make a deposit or not.
     * @param _isAdd Boolean indicating whether to lock or unlock asset. Should lock asset, if true.
     */
    function depositLockOrUnlock(
        ITraderBalanceVault traderBalanceVault,
        address _depositAsset,
        uint256 _amount,
        bool _takeDepositFromWallet,
        bool _isAdd
    ) internal {
        if (!_isAdd) {
            traderBalanceVault.unlockAsset(
                ITraderBalanceVault.UnlockAssetParams(msg.sender, msg.sender, _depositAsset, _amount)
            );
            return;
        }
        if (_takeDepositFromWallet) {
            if (_depositAsset == NATIVE_CURRENCY) {
                _require(msg.value >= _amount, Errors.INSUFFICIENT_DEPOSIT.selector);
                traderBalanceVault.increaseLockedBalance{value: _amount}(msg.sender, _depositAsset, _amount);
                if (msg.value > _amount) {
                    uint256 rest = msg.value - _amount;
                    traderBalanceVault.topUpAvailableBalance{value: rest}(msg.sender, NATIVE_CURRENCY, rest);
                }
                return;
            }
            TokenTransfersLibrary.doTransferFromTo(_depositAsset, msg.sender, address(traderBalanceVault), _amount);
            traderBalanceVault.increaseLockedBalance(msg.sender, _depositAsset, _amount);
            return;
        }
        traderBalanceVault.useTraderAssets(
            ITraderBalanceVault.LockAssetParams(
                msg.sender,
                address(0),
                _depositAsset,
                _amount,
                ITraderBalanceVault.OpenType.CREATE_LIMIT_ORDER
            )
        );
    }
}
