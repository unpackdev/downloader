// (c) 2023 Primex.finance
// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

import "./IERC20Metadata.sol";
import "./AggregatorV3Interface.sol";
import "./IERC165.sol";
import "./BytesLib.sol";
import "./WadRayMath.sol";

import "./Constants.sol";
import "./IDexAdapter.sol";
import "./IPriceOracle.sol";
import "./IPrimexDNS.sol";
import "./IBucket.sol";
import "./IPositionManager.sol";
import "./ITraderBalanceVault.sol";
import "./TokenTransfersLibrary.sol";

import "./Errors.sol";

library PrimexPricingLibrary {
    using WadRayMath for uint256;
    using BytesLib for bytes;

    struct Route {
        uint256 shares;
        SwapPath[] paths;
    }

    struct SwapPath {
        string dexName;
        bytes encodedPath;
    }

    struct MultiSwapParams {
        address tokenA;
        address tokenB;
        uint256 amountTokenA;
        Route[] routes;
        address dexAdapter;
        address receiver;
        uint256 deadline;
    }

    struct MultiSwapVars {
        uint256 sumOfShares;
        uint256 balance;
        uint256 amountOnDex;
        uint256 remainder;
        Route route;
    }

    struct AmountParams {
        address tokenA;
        address tokenB;
        uint256 amount;
        Route[] routes;
        address dexAdapter;
        address primexDNS;
    }

    struct LiquidationPriceCalculationParams {
        address bucket;
        address positionAsset;
        uint256 limitPrice;
        uint256 leverage;
    }

    struct DepositData {
        uint256 protocolFee;
        address depositAsset;
        uint256 depositAmount;
        uint256 leverage;
    }

    /**
     * @param depositData the deposit data through which the protocol fee can be calculated
     * if the position is opened through an order using deposit asset
     * @param feeToken An asset in which the fee will be paid. At this point it could be the pmx, the epmx or a native currency
     * @param isSwapFromWallet bool, the protocol fee is taken from the user wallet or from the Vault
     * @param trader trader address
     * @param priceOracle PriceOracle contract address
     * @param orderType Type of possible order in Primex protocol
     * @param traderBalanceVault TraderBalanceVault contract address
     * @param primexDNS PrimexDNS contract address
     */
    struct ProtocolFeeParams {
        DepositData depositData;
        address feeToken;
        bool isSwapFromWallet;
        address trader;
        address priceOracle;
        IPrimexDNSStorage.OrderType orderType;
        bool calculateFee;
        ITraderBalanceVault traderBalanceVault;
        IPrimexDNS primexDNS;
    }

    /**
     * The struct for payProtocolFee function
     */
    struct ProtocolFeeVars {
        bool fromLocked;
        address treasury;
    }

    /**
     * The struct for getLiquidationPrice and getLiquidationPriceByOrder functions
     */
    struct LiquidationPriceData {
        IBucket bucket;
        IPositionManager positionManager;
        IPriceOracle priceOracle;
        IERC20Metadata borrowedAsset;
    }

    event Withdraw(
        address indexed withdrawer,
        address borrowAssetReceiver,
        address borrowedAsset,
        uint256 amount,
        uint256 timestamp
    );

    /**
     * @notice Encodes the given parameters into a bytes array based on the specified DEX type.
     * @param path The token path for the swap.
     * @param dexRouter The address of the DEX router.
     * @param ancillaryData Additional data required for certain DEX types.
     * @param dexAdapter The address of the DEX adapter.
     * @param isAmountToBuy A flag indicating whether it is the path for the swap with fixed amountIn or amountOut.
     * Swap with fixed amountIn, if true.
     * @return The encoded bytes array.
     */
    function encodePath(
        address[] memory path,
        address dexRouter,
        bytes32 ancillaryData,
        address dexAdapter,
        bool isAmountToBuy
    ) external view returns (bytes memory) {
        IDexAdapter.DexType type_ = IDexAdapter(dexAdapter).dexType(dexRouter);

        if (type_ == IDexAdapter.DexType.UniswapV2 || type_ == IDexAdapter.DexType.Meshswap) {
            return abi.encode(path);
        }
        if (type_ == IDexAdapter.DexType.UniswapV3) {
            if (isAmountToBuy)
                return bytes.concat(bytes20(path[1]), bytes3(uint24(uint256(ancillaryData))), bytes20(path[0]));
            return bytes.concat(bytes20(path[0]), bytes3(uint24(uint256(ancillaryData))), bytes20(path[1]));
        }
        if (type_ == IDexAdapter.DexType.AlgebraV3) {
            if (isAmountToBuy) return bytes.concat(bytes20(path[1]), bytes20(path[0]));
            return bytes.concat(bytes20(path[0]), bytes20(path[1]));
        }
        if (type_ == IDexAdapter.DexType.Curve) {
            address[] memory pools = new address[](1);
            pools[0] = address(uint160(uint256(ancillaryData)));
            return abi.encode(path, pools);
        }
        if (type_ == IDexAdapter.DexType.Balancer) {
            int256[] memory limits = new int256[](2);
            limits[0] = type(int256).max;
            bytes32[] memory pools = new bytes32[](1);
            pools[0] = ancillaryData;
            return abi.encode(path, pools, limits);
        }
        _revert(Errors.UNKNOWN_DEX_TYPE.selector);
    }

    /**
     * @notice Wrapped getAmountsOut to the dex
     * @param _params parameters necessary to get amount out
     * @return the amount of `tokenB` by the amount of 'tokenA' on dexes
     */
    function getAmountOut(AmountParams memory _params) public returns (uint256) {
        _require(_params.tokenA != _params.tokenB, Errors.IDENTICAL_ASSETS.selector);
        _require(
            IERC165(address(_params.primexDNS)).supportsInterface(type(IPrimexDNS).interfaceId),
            Errors.ADDRESS_NOT_SUPPORTED.selector
        );

        uint256 sumOfShares;
        for (uint256 i; i < _params.routes.length; i++) {
            sumOfShares += _params.routes[i].shares;
        }
        _require(sumOfShares > 0, Errors.SUM_OF_SHARES_SHOULD_BE_GREATER_THAN_ZERO.selector);

        uint256 remainder = _params.amount;
        uint256 sum;
        uint256 amountOnDex;
        Route memory route;
        IDexAdapter.GetAmountsParams memory getAmountsParams;
        address[] memory path;

        for (uint256 i; i < _params.routes.length; i++) {
            route = _params.routes[i];
            amountOnDex = i == _params.routes.length - 1 ? remainder : (_params.amount * route.shares) / sumOfShares;
            remainder -= amountOnDex;

            for (uint256 j; j < route.paths.length; j++) {
                getAmountsParams.encodedPath = route.paths[j].encodedPath;
                getAmountsParams.amount = amountOnDex;
                getAmountsParams.dexRouter = IPrimexDNS(_params.primexDNS).getDexAddress(route.paths[j].dexName);
                path = decodePath(getAmountsParams.encodedPath, getAmountsParams.dexRouter, _params.dexAdapter);
                _require(path.length >= 2, Errors.INCORRECT_PATH.selector);
                amountOnDex = IDexAdapter(_params.dexAdapter).getAmountsOut(getAmountsParams)[1];
            }
            sum += amountOnDex;
        }

        return sum;
    }

    /**
     * @notice Wrapped getAmountIn to the dex
     * @param _params parameters necessary to get amount in
     * @return the amount of `tokenA` by the amount of 'tokenB' on dexes
     */
    function getAmountIn(AmountParams memory _params) public returns (uint256) {
        _require(_params.tokenA != _params.tokenB, Errors.IDENTICAL_ASSETS.selector);
        _require(
            IERC165(address(_params.primexDNS)).supportsInterface(type(IPrimexDNS).interfaceId),
            Errors.ADDRESS_NOT_SUPPORTED.selector
        );

        uint256 sumOfShares;
        for (uint256 i; i < _params.routes.length; i++) {
            sumOfShares += _params.routes[i].shares;
        }
        _require(sumOfShares > 0, Errors.SUM_OF_SHARES_SHOULD_BE_GREATER_THAN_ZERO.selector);

        uint256 remainder = _params.amount;
        uint256 sum;
        uint256 amountOnDex;
        Route memory route;
        IDexAdapter.GetAmountsParams memory getAmountsParams;
        address[] memory path;

        for (uint256 i; i < _params.routes.length; i++) {
            route = _params.routes[i];
            amountOnDex = i == _params.routes.length - 1 ? remainder : (_params.amount * route.shares) / sumOfShares;
            remainder -= amountOnDex;
            for (uint256 j; j < route.paths.length; j++) {
                getAmountsParams.encodedPath = route.paths[route.paths.length - 1 - j].encodedPath;
                getAmountsParams.amount = amountOnDex;
                getAmountsParams.dexRouter = IPrimexDNS(_params.primexDNS).getDexAddress(
                    route.paths[route.paths.length - 1 - j].dexName
                );
                path = decodePath(getAmountsParams.encodedPath, getAmountsParams.dexRouter, _params.dexAdapter);
                _require(path.length >= 2, Errors.INCORRECT_PATH.selector);
                amountOnDex = IDexAdapter(_params.dexAdapter).getAmountsIn(getAmountsParams)[0];
            }
            sum += amountOnDex;
        }

        return sum;
    }

    /**
     * @notice Calculates the amount of deposit assets in borrowed assets.
     * @param _params The parameters for the calculation.
     * @param _isThirdAsset A flag indicating if deposit is in a third asset.
     * @param _priceOracle The address of the price oracle.
     * @return The amount of deposit assets is measured in borrowed assets.
     */
    function getDepositAmountInBorrowed(
        AmountParams memory _params,
        bool _isThirdAsset,
        address _priceOracle
    ) public returns (uint256) {
        _require(
            IERC165(_params.primexDNS).supportsInterface(type(IPrimexDNS).interfaceId) &&
                IERC165(_priceOracle).supportsInterface(type(IPriceOracle).interfaceId),
            Errors.ADDRESS_NOT_SUPPORTED.selector
        );
        if (_params.tokenA == _params.tokenB) {
            _require(_params.routes.length == 0, Errors.DEPOSITED_TO_BORROWED_ROUTES_LENGTH_SHOULD_BE_0.selector);
            return _params.amount;
        }

        uint256 depositAmountInBorrowed = getAmountOut(_params);
        if (_isThirdAsset) {
            uint256 oracleDepositAmountOut = getOracleAmountsOut(
                _params.tokenA,
                _params.tokenB,
                _params.amount,
                _priceOracle
            );
            if (depositAmountInBorrowed > oracleDepositAmountOut) depositAmountInBorrowed = oracleDepositAmountOut;
        }

        return depositAmountInBorrowed;
    }

    /**
     * @notice Performs a multi-hop swap transaction using the specified parameters.
     * @dev This function executes a series of token swaps on different DEXs based on the provided routes.
     * @param _params The struct containing all the necessary parameters for the multi-hop swap.
     * @param _maximumOracleTolerableLimit The maximum tolerable limit in WAD format (1 WAD = 100%)
     * for the price difference between DEX and the oracle.
     * @param _primexDNS The address of the Primex DNS contract.
     * @param _priceOracle The address of the price oracle contract.
     * @param _needOracleTolerableLimitCheck Flag indicating whether to perform an oracle tolerable limit check.
     * @return The final balance of the _params.tokenB in the receiver's address after the multi-hop swap.
     */
    function multiSwap(
        MultiSwapParams memory _params,
        uint256 _maximumOracleTolerableLimit,
        address _primexDNS,
        address _priceOracle,
        bool _needOracleTolerableLimitCheck
    ) public returns (uint256) {
        _require(
            IERC165(_primexDNS).supportsInterface(type(IPrimexDNS).interfaceId) &&
                IERC165(_priceOracle).supportsInterface(type(IPriceOracle).interfaceId),
            Errors.ADDRESS_NOT_SUPPORTED.selector
        );
        MultiSwapVars memory vars;
        vars.balance = IERC20Metadata(_params.tokenB).balanceOf(_params.receiver);
        for (uint256 i; i < _params.routes.length; i++) {
            vars.sumOfShares += _params.routes[i].shares;
        }
        _require(vars.sumOfShares > 0, Errors.SUM_OF_SHARES_SHOULD_BE_GREATER_THAN_ZERO.selector);

        vars.remainder = _params.amountTokenA;
        IDexAdapter.SwapParams memory swapParams;
        swapParams.deadline = _params.deadline;

        for (uint256 i; i < _params.routes.length; i++) {
            vars.route = _params.routes[i];
            vars.amountOnDex = i == _params.routes.length - 1
                ? vars.remainder
                : (_params.amountTokenA * vars.route.shares) / vars.sumOfShares;
            vars.remainder -= vars.amountOnDex;
            swapParams.to = _params.dexAdapter;

            for (uint256 j; j < vars.route.paths.length; j++) {
                swapParams.encodedPath = vars.route.paths[j].encodedPath;
                swapParams.amountIn = vars.amountOnDex;
                swapParams.dexRouter = IPrimexDNS(_primexDNS).getDexAddress(vars.route.paths[j].dexName);
                if (j == vars.route.paths.length - 1) {
                    swapParams.to = _params.receiver;
                }
                vars.amountOnDex = IDexAdapter(_params.dexAdapter).swapExactTokensForTokens(swapParams)[1];
            }
        }

        vars.balance = IERC20Metadata(_params.tokenB).balanceOf(_params.receiver) - vars.balance;
        if (_needOracleTolerableLimitCheck) {
            _require(
                vars.balance >=
                    getOracleAmountsOut(_params.tokenA, _params.tokenB, _params.amountTokenA, _priceOracle).wmul(
                        WadRayMath.WAD - _maximumOracleTolerableLimit
                    ),
                Errors.DIFFERENT_PRICE_DEX_AND_ORACLE.selector
            );
        }

        return vars.balance;
    }

    /**
     * @notice Pays the protocol fee.
     * @dev This function transfers the protocol fee from the trader to the protocol treasury.
     * @param params The parameters for paying the protocol fee.
     * @return protocolFee The amount of the protocol fee in PMX or NATIVE_CURRENCY paid.
     */
    function payProtocolFee(ProtocolFeeParams memory params) public returns (uint256 protocolFee) {
        if (!params.isSwapFromWallet || params.feeToken != NATIVE_CURRENCY) {
            _require(msg.value == 0, Errors.DISABLED_TRANSFER_NATIVE_CURRENCY.selector);
        }
        ProtocolFeeVars memory vars;
        vars.treasury = params.primexDNS.treasury();
        vars.fromLocked = true;

        protocolFee = params.depositData.protocolFee;
        if (params.calculateFee) {
            protocolFee = calculateProtocolFee(
                params.depositData,
                params.primexDNS,
                params.priceOracle,
                params.orderType,
                params.feeToken
            );
            if (protocolFee == 0) return 0;
            vars.fromLocked = false;
            if (params.isSwapFromWallet) {
                if (params.feeToken == NATIVE_CURRENCY) {
                    _require(msg.value >= protocolFee, Errors.INSUFFICIENT_DEPOSIT.selector);
                    TokenTransfersLibrary.doTransferOutETH(vars.treasury, protocolFee);
                    if (msg.value > protocolFee) {
                        uint256 rest = msg.value - protocolFee;
                        params.traderBalanceVault.topUpAvailableBalance{value: rest}(msg.sender, NATIVE_CURRENCY, rest);
                    }
                } else {
                    TokenTransfersLibrary.doTransferFromTo(params.feeToken, params.trader, vars.treasury, protocolFee);
                }
                return protocolFee;
            }
        }

        params.traderBalanceVault.withdrawFrom(
            params.trader,
            vars.treasury,
            params.feeToken,
            protocolFee,
            vars.fromLocked
        );
    }

    /**
     * @notice Calculate and return protocol fee
     * @param _depositData The deposit data through which the protocol fee can be calculated.
     * @param _primexDNS The address of the PrimexDNS contract.
     * @param _priceOracle The address of the PriceOracle contract.
     * @param _orderType Type of possible order in Primex protocol
     * @param _feeToken An asset in which the fee will be paid. At this point it could be the pmx, the epmx or a native currency
     * @return The amount of the protocol fee in '_feeToken' which needs to be paid according to the specified deposit parameters.
     */
    function calculateProtocolFee(
        DepositData memory _depositData,
        IPrimexDNS _primexDNS,
        address _priceOracle,
        IPrimexDNSStorage.OrderType _orderType,
        address _feeToken
    ) public view returns (uint256) {
        uint256 feeRate = _primexDNS.feeRates(_orderType, _feeToken);
        if (feeRate == 0) return 0;
        uint256 nativeFeeRate = _feeToken == NATIVE_CURRENCY
            ? feeRate
            : _primexDNS.feeRates(_orderType, NATIVE_CURRENCY);

        _depositData.protocolFee = getOracleAmountsOut(
            _depositData.depositAsset,
            NATIVE_CURRENCY,
            _depositData.depositAmount.wmul(_depositData.leverage).wmul(nativeFeeRate),
            _priceOracle
        );

        (uint256 minFee, uint256 maxFee) = IPrimexDNSV2(address(_primexDNS)).feeRestrictions(_orderType);
        if (minFee > _depositData.protocolFee) {
            _depositData.protocolFee = minFee;
        } else if (maxFee < _depositData.protocolFee) {
            _depositData.protocolFee = maxFee;
        }

        if (_feeToken != NATIVE_CURRENCY) {
            _require(nativeFeeRate != 0, Errors.FEE_RATE_IN_NATIVE_IS_ZERO.selector);
            uint256 discountMultiplier = feeRate.wdiv(nativeFeeRate);
            _depositData.protocolFee = getOracleAmountsOut(
                NATIVE_CURRENCY,
                _feeToken,
                _depositData.protocolFee.wmul(discountMultiplier),
                _priceOracle
            );
        }

        return _depositData.protocolFee;
    }

    /**
     * @param _tokenA asset for sell
     * @param _tokenB asset to buy
     * @param _amountAssetA Amount tokenA to sell
     * @param _priceOracle PriceOracle contract address
     * @return returns the amount of `tokenB` by the `amountAssetA` by the price of the oracle
     */
    function getOracleAmountsOut(
        address _tokenA,
        address _tokenB,
        uint256 _amountAssetA,
        address _priceOracle
    ) public view returns (uint256) {
        _require(
            IERC165(_priceOracle).supportsInterface(type(IPriceOracle).interfaceId),
            Errors.ADDRESS_NOT_SUPPORTED.selector
        );
        if (_tokenA == _tokenB) {
            return _amountAssetA;
        }
        (uint256 exchangeRate, bool isForward) = IPriceOracle(_priceOracle).getExchangeRate(_tokenA, _tokenB);
        uint256 amountAssetB;
        uint256 multiplier1 = _getAssetMultiplier(_tokenA);
        uint256 multiplier2 = _getAssetMultiplier(_tokenB);

        if (isForward) {
            amountAssetB = (_amountAssetA * multiplier1).wmul(exchangeRate) / multiplier2;
        } else {
            amountAssetB = (_amountAssetA * multiplier1).wdiv(exchangeRate) / multiplier2;
        }
        return amountAssetB;
    }

    /**
     * @param _tokenA asset for sell
     * @param _tokenB asset to buy
     * @param _amountsAssetA An array of amounts of tokenA to sell
     * @param _priceOracle PriceOracle contract address
     * @return returns an array of amounts of `tokenB` by the `amountsAssetA` by the price of the oracle
     */
    function getBatchOracleAmountsOut(
        address _tokenA,
        address _tokenB,
        uint256[] memory _amountsAssetA,
        address _priceOracle
    ) public view returns (uint256[] memory) {
        _require(
            IERC165(_priceOracle).supportsInterface(type(IPriceOracle).interfaceId),
            Errors.ADDRESS_NOT_SUPPORTED.selector
        );
        if (_tokenA == _tokenB) {
            return _amountsAssetA;
        }
        uint256[] memory amountsAssetB = new uint256[](_amountsAssetA.length);
        (uint256 exchangeRate, bool isForward) = IPriceOracle(_priceOracle).getExchangeRate(_tokenA, _tokenB);
        uint256 multiplier1 = 10 ** (18 - IERC20Metadata(_tokenA).decimals());
        uint256 multiplier2 = 10 ** (18 - IERC20Metadata(_tokenB).decimals());

        if (isForward) {
            for (uint256 i; i < _amountsAssetA.length; i++) {
                amountsAssetB[i] = (_amountsAssetA[i] * multiplier1).wmul(exchangeRate) / multiplier2;
            }
        } else {
            for (uint256 i; i < _amountsAssetA.length; i++) {
                amountsAssetB[i] = (_amountsAssetA[i] * multiplier1).wdiv(exchangeRate) / multiplier2;
            }
        }
        return amountsAssetB;
    }

    /**
     * @notice Calculates the liquidation price for a position.
     * @dev liquidationPrice = (feeBuffer * debt) /
     * ((1 - securityBuffer) * (1 - oracleTolerableLimit) * (1 - priceDrop) * positionAmount))
     * @param _bucket The address of the related bucket.
     * @param _positionAsset The address of the position asset.
     * @param _positionAmount The size of the opened position.
     * @param _positionDebt The debt amount in debtTokens associated with the position.
     * @return The calculated liquidation price in borrowed asset.
     */
    function getLiquidationPrice(
        address _bucket,
        address _positionAsset,
        uint256 _positionAmount,
        uint256 _positionDebt
    ) public view returns (uint256) {
        _require(_positionAsset != address(0), Errors.ADDRESS_NOT_SUPPORTED.selector);
        LiquidationPriceData memory data;
        data.bucket = IBucket(_bucket);

        (, bool tokenAllowed) = data.bucket.allowedAssets(_positionAsset);
        _require(tokenAllowed, Errors.TOKEN_NOT_SUPPORTED.selector);

        data.positionManager = data.bucket.positionManager();
        data.borrowedAsset = data.bucket.borrowedAsset();
        data.priceOracle = data.positionManager.priceOracle();

        uint256 multiplier1 = 10 ** (18 - data.borrowedAsset.decimals());
        uint256 denominator = (WadRayMath.WAD - data.positionManager.securityBuffer())
            .wmul(
                WadRayMath.WAD -
                    data.positionManager.getOracleTolerableLimit(_positionAsset, address(data.borrowedAsset))
            )
            .wmul(WadRayMath.WAD - data.priceOracle.getPairPriceDrop(_positionAsset, address(data.borrowedAsset)))
            .wmul(_positionAmount) * 10 ** (18 - IERC20Metadata(_positionAsset).decimals());
        // numerator = data.bucket.feeBuffer().wmul(_positionDebt) * multiplier1;
        return (data.bucket.feeBuffer().wmul(_positionDebt) * multiplier1).wdiv(denominator) / multiplier1;
    }

    /**
     * @notice Validates if a position meets the minimum size requirement.
     * @param _minPositionSize The minimum position size.
     * @param _minPositionAsset The asset associated with the minimum position size.
     * @param _amount The amount of the asset in the position.
     * @param _asset The asset associated with the position.
     * @param _priceOracle The address of the price oracle contract.
     */
    function validateMinPositionSize(
        uint256 _minPositionSize,
        address _minPositionAsset,
        uint256 _amount,
        address _asset,
        address _priceOracle
    ) public view {
        _require(
            isCorrespondsMinPositionSize(_minPositionSize, _minPositionAsset, _asset, _amount, _priceOracle),
            Errors.INSUFFICIENT_POSITION_SIZE.selector
        );
    }

    /**
     * @notice Checks if the given amount of _asset corresponds to the minimum position size _minPositionSize,
     * based on the _minPositionAsset and the provided _priceOracle.
     * Returns true if the amount corresponds to or exceeds the minimum position size, otherwise returns false.
     * @param _minPositionSize The minimum position size required.
     * @param _minPositionAsset The address of the asset used for determining the minimum position size.
     * @param _asset The address of the asset being checked.
     * @param _amount The amount of _asset being checked.
     * @param _priceOracle The address of the price oracle contract.
     * @return A boolean value indicating whether the amount corresponds to or exceeds the minimum position size.
     */
    function isCorrespondsMinPositionSize(
        uint256 _minPositionSize,
        address _minPositionAsset,
        address _asset,
        uint256 _amount,
        address _priceOracle
    ) public view returns (bool) {
        if (_minPositionSize == 0) return true;

        uint256 amountInMinPositionAsset = getOracleAmountsOut(_asset, _minPositionAsset, _amount, _priceOracle);
        return amountInMinPositionAsset >= _minPositionSize;
    }

    /**
     * @notice Decodes an encoded path and returns an array of addresses.
     * @param encodedPath The encoded path to be decoded.
     * @param dexRouter The address of the DEX router.
     * @param dexAdapter The address of the DEX adapter.
     * @return path An array of addresses representing the decoded path.
     */
    function decodePath(
        bytes memory encodedPath,
        address dexRouter,
        address dexAdapter
    ) public view returns (address[] memory path) {
        IDexAdapter.DexType type_ = IDexAdapter(dexAdapter).dexType(dexRouter);

        if (type_ == IDexAdapter.DexType.UniswapV2 || type_ == IDexAdapter.DexType.Meshswap) {
            path = abi.decode(encodedPath, (address[]));
        } else if (type_ == IDexAdapter.DexType.UniswapV3) {
            uint256 skip;
            uint256 offsetSize = 23; // address size(20) + fee size(3)
            uint256 pathLength = encodedPath.length / offsetSize + 1;
            path = new address[](pathLength);
            for (uint256 i; i < pathLength; i++) {
                path[i] = encodedPath.toAddress(skip, encodedPath.length);
                skip += offsetSize;
            }
        } else if (type_ == IDexAdapter.DexType.Curve) {
            (path, ) = abi.decode(encodedPath, (address[], address[]));
        } else if (type_ == IDexAdapter.DexType.Balancer) {
            (path, , ) = abi.decode(encodedPath, (address[], bytes32[], int256[]));
        } else if (type_ == IDexAdapter.DexType.AlgebraV3) {
            uint256 skip;
            uint256 offsetSize = 20; // address size(20)
            uint256 pathLength = encodedPath.length / offsetSize;
            path = new address[](pathLength);
            for (uint256 i; i < pathLength; i++) {
                path[i] = encodedPath.toAddress(skip, encodedPath.length);
                skip += offsetSize;
            }
        } else {
            _revert(Errors.UNKNOWN_DEX_TYPE.selector);
        }
    }

    /**
     * @notice Retrieves the price from two price feeds.
     * @dev This function returns the price ratio between the base price and the quote price.
     * @param basePriceFeed The address of the base price feed (AggregatorV3Interface).
     * @param quotePriceFeed The address of the quote price feed (AggregatorV3Interface).
     * @param roundBaseFeed The round ID of the base price feed.
     * @param roundQuoteFeed The round ID of the quote price feed.
     * @param checkedTimestamp The timestamp used to filter relevant prices. Set to 0 to consider all prices.
     * @return The price ratio in WAD format between the base price and the quote price, and the timestamp of the latest price.
     */
    function getPriceFromFeeds(
        AggregatorV3Interface basePriceFeed,
        AggregatorV3Interface quotePriceFeed,
        uint80 roundBaseFeed,
        uint80 roundQuoteFeed,
        uint256 checkedTimestamp
    ) internal view returns (uint256, uint256) {
        (, int256 basePrice, , uint256 basePriceUpdatedAt, ) = basePriceFeed.getRoundData(roundBaseFeed);
        (, , , uint256 basePriceUpdatedAtNext, ) = basePriceFeed.getRoundData(roundBaseFeed + 1);
        // update to current timestamp if roundBaseFeed is last round
        if (basePriceUpdatedAtNext == 0) basePriceUpdatedAtNext = block.timestamp;

        (, int256 quotePrice, , uint256 quotePriceUpdatedAt, ) = quotePriceFeed.getRoundData(roundQuoteFeed);
        (, , , uint256 quotePriceUpdatedAtNext, ) = quotePriceFeed.getRoundData(roundQuoteFeed + 1);
        // update to current timestamp if roundQuoteFeed is last round
        if (quotePriceUpdatedAtNext == 0) quotePriceUpdatedAtNext = block.timestamp;

        _require(basePriceUpdatedAt > 0 && quotePriceUpdatedAt > 0, Errors.DATA_FOR_ROUND_DOES_NOT_EXIST.selector);

        // we work only with prices that were relevant after position creation
        _require(
            checkedTimestamp == 0 ||
                (basePriceUpdatedAtNext > checkedTimestamp && quotePriceUpdatedAtNext > checkedTimestamp),
            Errors.HIGH_PRICE_TIMESTAMP_IS_INCORRECT.selector
        );
        // there should be an intersection between their duration
        _require(
            quotePriceUpdatedAt < basePriceUpdatedAtNext && basePriceUpdatedAt < quotePriceUpdatedAtNext,
            Errors.NO_PRICE_FEED_INTERSECTION.selector
        );
        //the return value will always be 18 decimals if the basePrice and quotePrice have the same decimals
        return (
            uint256(basePrice).wdiv(uint256(quotePrice)),
            quotePriceUpdatedAt < basePriceUpdatedAt ? quotePriceUpdatedAt : basePriceUpdatedAt
        );
    }

    /**
     * @notice Returns the asset multiplier for a given asset.
     * @dev If the asset is the native currency, the function returns 1.
     * If the asset is USD, the function returns the value stored in the constant USD_MULTIPLIER.
     * For any other asset, the function calculates the multiplier based on the number of decimals of the token.
     * @param _asset The address of the asset.
     * @return The asset multiplier. It is a number with 10 raised to a power of decimals of a given asset.
     */
    function _getAssetMultiplier(address _asset) internal view returns (uint256) {
        if (_asset == NATIVE_CURRENCY) return 1;
        if (_asset == USD) return USD_MULTIPLIER;

        return 10 ** (18 - IERC20Metadata(_asset).decimals());
    }
}
