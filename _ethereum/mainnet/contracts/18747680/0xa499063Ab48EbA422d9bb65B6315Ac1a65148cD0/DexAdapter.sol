// (c) 2023 Primex.finance
// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

import "./IERC20.sol";
import "./IERC165.sol";
import "./IAccessControl.sol";
import "./ISwapRouter.sol";
import "./ISwapRouter.sol";
import "./IUniswapV2Router02.sol";
import "./IQuoter.sol";
import "./IQuoter.sol";
import "./WadRayMath.sol";
import "./V3Path.sol";

import "./Errors.sol";

import "./Constants.sol";
import "./IBalancer.sol";
import "./IAsset.sol";
import "./IDexAdapter.sol";
import "./ICurveRouter.sol";

contract DexAdapter is IDexAdapter, IERC165 {
    using WadRayMath for uint256;
    using V3Path for bytes;

    /**
     * @inheritdoc IDexAdapter
     */
    mapping(address => DexType) public override dexType;

    /**
     * @inheritdoc IDexAdapter
     */
    mapping(address => address) public override quoters;

    /**
     * @inheritdoc IDexAdapter
     */
    address public immutable override registry;

    /**
     * @dev Throws if caller is not granted with _role
     * @param _role The role that is being checked for a function caller
     */
    modifier onlyRole(bytes32 _role) {
        _require(IAccessControl(registry).hasRole(_role, msg.sender), Errors.FORBIDDEN.selector);
        _;
    }

    constructor(address _registry) {
        _require(
            IERC165(_registry).supportsInterface(type(IAccessControl).interfaceId),
            Errors.ADDRESS_NOT_SUPPORTED.selector
        );

        registry = _registry;
    }

    /**
     * @inheritdoc IDexAdapter
     */
    function setQuoter(address _dexRouter, address _quoter) external override onlyRole(MEDIUM_TIMELOCK_ADMIN) {
        _require(uint256(dexType[_dexRouter]) > 0, Errors.DEX_ROUTER_NOT_SUPPORTED.selector);
        _require(_quoter != address(0), Errors.QUOTER_NOT_SUPPORTED.selector);
        quoters[_dexRouter] = _quoter;
        emit QuoterChanged(_dexRouter, _quoter);
    }

    /**
     * @inheritdoc IDexAdapter
     */
    function setDexType(address _dexRouter, uint256 _dexType) external override onlyRole(MEDIUM_TIMELOCK_ADMIN) {
        _require(_dexRouter != address(0), Errors.ADDRESS_NOT_SUPPORTED.selector);
        dexType[_dexRouter] = DexType(_dexType);
        emit DexTypeChanged(_dexRouter, _dexType);
    }

    /**
     * @inheritdoc IDexAdapter
     */
    function swapExactTokensForTokens(
        SwapParams memory _params
    ) external override onlyRole(VAULT_ACCESS_ROLE) returns (uint256[3] memory) {
        _require(_params.to != address(0) && _params.dexRouter != address(0), Errors.ADDRESS_NOT_SUPPORTED.selector);
        _require(_params.amountIn != 0, Errors.ZERO_AMOUNT_IN.selector);
        DexType type_ = dexType[_params.dexRouter];

        if (type_ == DexType.UniswapV2 || type_ == DexType.Meshswap) {
            return _swapWithUniswapV2(_params);
        } else if (type_ == DexType.UniswapV3) {
            return _swapWithUniswapV3(_params);
        } else if (type_ == DexType.Curve) {
            return _swapWithCurve(_params);
        } else if (type_ == DexType.Balancer) {
            return _swapWithBalancer(_params);
        } else if (type_ == DexType.AlgebraV3) {
            return _swapWithAlgebraV3(_params);
        } else {
            _revert(Errors.UNKNOWN_DEX_TYPE.selector);
        }
    }

    /**
     * @inheritdoc IDexAdapter
     */
    function getAmountsOut(GetAmountsParams memory _params) external override returns (uint256[3] memory) {
        _checkAmountsParams(_params);
        DexType type_ = dexType[_params.dexRouter];

        if (type_ == DexType.UniswapV2 || type_ == DexType.Meshswap) {
            return _getAmountsWithUniswapV2(_params);
        } else if (type_ == DexType.UniswapV3) {
            return _getAmountsWithUniswapV3(_params);
        } else if (type_ == DexType.Curve) {
            return _getAmountsWithCurve(_params);
        } else if (type_ == DexType.Balancer) {
            return _getAmountsWithBalancer(_params);
        } else if (type_ == DexType.AlgebraV3) {
            return _getAmountsWithAlgebraV3(_params);
        } else {
            _revert(Errors.UNKNOWN_DEX_TYPE.selector);
        }
    }

    /**
     * @inheritdoc IDexAdapter
     */
    function getAmountsIn(GetAmountsParams memory _params) external override returns (uint256[3] memory) {
        _checkAmountsParams(_params);
        DexType type_ = dexType[_params.dexRouter];

        if (type_ == DexType.UniswapV2 || type_ == DexType.Meshswap) {
            return _getAmountsInWithUniswapV2(_params);
        } else if (type_ == DexType.UniswapV3) {
            return _getAmountsInWithUniswapV3(_params);
        } else if (type_ == DexType.Curve) {
            return _getAmountsInWithCurve(_params);
        } else if (type_ == DexType.Balancer) {
            return _getAmountsInWithBalancer(_params);
        } else if (type_ == DexType.AlgebraV3) {
            return _getAmountsInWithAlgebraV3(_params);
        } else {
            _revert(Errors.UNKNOWN_DEX_TYPE.selector);
        }
    }

    /**
     * @inheritdoc IDexAdapter
     */
    function getGas(address dexRouter) external view override returns (uint256) {
        _require(dexRouter != address(0), Errors.ADDRESS_NOT_SUPPORTED.selector);
        DexType type_ = dexType[dexRouter];
        // These values are average taken from the gas tracker in etherscan
        // The actual values depend on many variables especially the more complex dex such as uniswap v3
        if (type_ == DexType.UniswapV2) {
            return 152809;
        } else if (type_ == DexType.UniswapV3 || type_ == DexType.AlgebraV3) {
            return 184523;
        } else if (type_ == DexType.Curve) {
            return 183758;
        } else if (type_ == DexType.Balancer) {
            return 196625;
        } else if (type_ == DexType.Meshswap) {
            return 271000;
        } else {
            _revert(Errors.UNKNOWN_DEX_TYPE.selector);
        }
    }

    /**
     * @notice Interface checker
     * @param _interfaceId The interface id to check
     */
    function supportsInterface(bytes4 _interfaceId) public view virtual override returns (bool) {
        return _interfaceId == type(IERC165).interfaceId || _interfaceId == type(IDexAdapter).interfaceId;
    }

    function _getAmountsWithBalancer(GetAmountsParams memory _params) internal returns (uint256[3] memory) {
        (address[] memory path, bytes32[] memory pools, ) = abi.decode(
            _params.encodedPath,
            (address[], bytes32[], int256[])
        );
        (IAsset[] memory assets, IBalancer.BatchSwapStep[] memory steps) = _getBalancerSwapSteps(
            path,
            pools,
            _params.amount
        );

        IBalancer.FundManagement memory fundManagement = IBalancer.FundManagement({
            sender: address(this),
            fromInternalBalance: false,
            recipient: payable(address(this)),
            toInternalBalance: false
        });

        int256[] memory deltas;
        deltas = IBalancer(_params.dexRouter).queryBatchSwap(
            IBalancer.SwapKind.GIVEN_IN,
            steps,
            assets,
            fundManagement
        );
        /// @notice - queryBatchSwap will return a delta for each token in the assets array and last asset should be tokenOut
        _require(deltas[deltas.length - 1] <= 0, Errors.DELTA_OF_TOKEN_OUT_HAS_POSITIVE_VALUE.selector);
        uint256 amountOut = uint256(deltas[deltas.length - 1] * -1);
        return [_params.amount, amountOut, 0];
    }

    function _getAmountsInWithBalancer(GetAmountsParams memory _params) internal returns (uint256[3] memory) {
        (address[] memory path, bytes32[] memory pools, ) = abi.decode(
            _params.encodedPath,
            (address[], bytes32[], int256[])
        );
        IAsset[] memory assets = new IAsset[](path.length);
        IBalancer.BatchSwapStep[] memory steps = new IBalancer.BatchSwapStep[](pools.length);

        IBalancer.FundManagement memory fundManagement = IBalancer.FundManagement({
            sender: address(this),
            fromInternalBalance: false,
            recipient: payable(address(this)),
            toInternalBalance: false
        });
        for (uint256 i; i < path.length - 1; i++) {
            assets[i] = IAsset(path[i]);
            steps[path.length - 2 - i] = IBalancer.BatchSwapStep({
                poolId: pools[i],
                assetInIndex: i,
                assetOutIndex: i + 1,
                amount: 0,
                userData: "0x"
            });
        }
        steps[0].amount = _params.amount;
        assets[path.length - 1] = IAsset(path[path.length - 1]);

        int256[] memory deltas;
        deltas = IBalancer(_params.dexRouter).queryBatchSwap(
            IBalancer.SwapKind.GIVEN_OUT,
            steps,
            assets,
            fundManagement
        );
        _require(deltas[0] >= 0, Errors.DELTA_OF_TOKEN_IN_HAS_NEGATIVE_VALUE.selector);
        return [uint256(deltas[0]), _params.amount, 0];
    }

    function _getAmountsWithUniswapV3(GetAmountsParams memory _params) internal returns (uint256[3] memory) {
        address quoter = quoters[_params.dexRouter];
        _require(address(quoter) != address(0), Errors.QUOTER_IS_NOT_PROVIDED.selector);
        uint256 amountOut = IQuoter(quoter).quoteExactInput(_params.encodedPath, _params.amount);
        return [_params.amount, amountOut, 0];
    }

    function _getAmountsInWithUniswapV3(GetAmountsParams memory _params) internal returns (uint256[3] memory) {
        address quoter = quoters[_params.dexRouter];
        _require(address(quoter) != address(0), Errors.QUOTER_IS_NOT_PROVIDED.selector);
        uint256 amountIn = IQuoter(quoter).quoteExactOutput(_params.encodedPath, _params.amount);
        return [amountIn, _params.amount, 0];
    }

    function _getAmountsWithAlgebraV3(GetAmountsParams memory _params) internal returns (uint256[3] memory) {
        address quoter = quoters[_params.dexRouter];
        _require(address(quoter) != address(0), Errors.QUOTER_IS_NOT_PROVIDED.selector);
        (uint256 amountOut, ) = IQuoterAlgebraV3(quoter).quoteExactInput(_params.encodedPath, _params.amount);
        return [_params.amount, amountOut, 0];
    }

    function _getAmountsInWithAlgebraV3(GetAmountsParams memory _params) internal returns (uint256[3] memory) {
        address quoter = quoters[_params.dexRouter];
        _require(address(quoter) != address(0), Errors.QUOTER_IS_NOT_PROVIDED.selector);
        (uint256 amountIn, ) = IQuoterAlgebraV3(quoter).quoteExactOutput(_params.encodedPath, _params.amount);
        return [amountIn, _params.amount, 0];
    }

    function _getAmountsWithCurve(GetAmountsParams memory _params) internal view returns (uint256[3] memory) {
        (address[] memory path, address[] memory pools) = abi.decode(_params.encodedPath, (address[], address[]));
        uint256 amountOut = _getExchangeAmountCurve(_params.amount, _params.dexRouter, path, pools);

        return [_params.amount, amountOut, 0];
    }

    function _getExchangeAmountCurve(
        uint256 amount,
        address dexRouter,
        address[] memory path,
        address[] memory pools
    ) internal view returns (uint256) {
        uint256 amountOut = amount;

        for (uint256 i; i < path.length - 1; i++) {
            amountOut = ICurveRouter(dexRouter).get_exchange_amount(pools[i], path[i], path[i + 1], amountOut);
        }
        return amountOut;
    }

    function _getAmountsInWithCurve(GetAmountsParams memory _params) internal view returns (uint256[3] memory) {
        (address[] memory path, address[] memory pools) = abi.decode(_params.encodedPath, (address[], address[]));
        uint256 inverseAmount = _getExchangeAmountCurve(
            _params.amount,
            _params.dexRouter,
            _reverseArray(path),
            _reverseArray(pools)
        );
        //expanding the search to +50% and -50% from the inverseAmount
        // mul by 0.5 WAD
        uint256 minValue = inverseAmount.wmul(5e17);
        // mul by 1.5 WAD
        uint256 maxValue = inverseAmount.wmul(15e17);
        uint256 amountIn;
        for (uint256 i; i <= 100; i++) {
            // first iteration checks the inverseAmount: (0.5 + 1.5) / 2
            uint256 middle = (minValue + maxValue) / 2;
            if (middle == amountIn) break;
            amountIn = middle;
            uint256 amountOut = _getExchangeAmountCurve(amountIn, _params.dexRouter, path, pools);
            if (amountOut == _params.amount) break;
            else if (amountOut < _params.amount) minValue = amountIn;
            else maxValue = amountIn;
        }
        return [amountIn, _params.amount, 0];
    }

    function _getAmountsWithUniswapV2(GetAmountsParams memory _params) internal view returns (uint256[3] memory) {
        address[] memory path = abi.decode(_params.encodedPath, (address[]));

        uint256[] memory amounts = IUniswapV2Router02(_params.dexRouter).getAmountsOut(_params.amount, path);

        return [_params.amount, amounts[amounts.length - 1], 0];
    }

    function _getAmountsInWithUniswapV2(GetAmountsParams memory _params) internal view returns (uint256[3] memory) {
        address[] memory path = abi.decode(_params.encodedPath, (address[]));

        uint256[] memory amounts = IUniswapV2Router02(_params.dexRouter).getAmountsIn(_params.amount, path);

        return [amounts[0], _params.amount, 0];
    }

    function _reverseArray(address[] memory source) internal pure returns (address[] memory) {
        uint256 length = source.length;
        address[] memory result = new address[](length);
        for (uint256 i; i < length; i++) {
            result[length - 1 - i] = source[i];
        }
        return result;
    }

    function _checkAmountsParams(GetAmountsParams memory _params) internal pure {
        _require(_params.dexRouter != address(0), Errors.ADDRESS_NOT_SUPPORTED.selector);
        _require(_params.amount != 0, Errors.ZERO_AMOUNT.selector);
    }

    function _getBalancerSwapSteps(
        address[] memory path,
        bytes32[] memory pools,
        uint256 amount
    ) internal pure returns (IAsset[] memory assets, IBalancer.BatchSwapStep[] memory steps) {
        assets = new IAsset[](path.length);
        steps = new IBalancer.BatchSwapStep[](pools.length);

        for (uint256 i; i < path.length - 1; i++) {
            assets[i] = IAsset(path[i]);
            steps[i] = IBalancer.BatchSwapStep({
                poolId: pools[i],
                assetInIndex: i,
                assetOutIndex: i + 1,
                amount: 0,
                userData: "0x"
            });
        }
        steps[0].amount = amount;
        assets[path.length - 1] = IAsset(path[path.length - 1]);
    }

    function _swapWithUniswapV2(SwapParams memory _params) private returns (uint256[3] memory) {
        address[] memory path = abi.decode(_params.encodedPath, (address[]));
        IERC20(path[0]).approve(_params.dexRouter, _params.amountIn);
        uint256[] memory amounts;

        amounts = IUniswapV2Router02(_params.dexRouter).swapExactTokensForTokens(
            _params.amountIn,
            _params.amountOutMin,
            path,
            _params.to,
            _params.deadline
        );

        return [_params.amountIn, amounts[amounts.length - 1], 0];
    }

    function _swapWithUniswapV3(SwapParams memory _params) private returns (uint256[3] memory) {
        address tokenIn = _params.encodedPath.decodeFirstToken();
        IERC20(tokenIn).approve(_params.dexRouter, _params.amountIn);

        ISwapRouter.ExactInputParams memory params = ISwapRouter.ExactInputParams({
            path: _params.encodedPath,
            recipient: _params.to,
            deadline: _params.deadline,
            amountIn: _params.amountIn,
            amountOutMinimum: _params.amountOutMin
        });
        uint256 amountOut;
        // slither-disable-next-line unused-return
        try ISwapRouter(_params.dexRouter).exactInput(params) returns (uint256 _amountOut) {
            // slither-disable-next-line variable-scope
            amountOut = _amountOut;
        } catch Error(string memory err) {
            // slither-disable-next-line variable-scope
            revert(err);
        } catch (bytes memory) {
            _revert(Errors.REVERTED_WITHOUT_A_STRING_TRY_TO_CHECK_THE_ANCILLARY_DATA.selector);
        }

        return [_params.amountIn, amountOut, 0];
    }

    function _swapWithAlgebraV3(SwapParams memory _params) private returns (uint256[3] memory) {
        address tokenIn = _params.encodedPath.decodeFirstToken();
        IERC20(tokenIn).approve(_params.dexRouter, _params.amountIn);

        ISwapRouterAlgebraV3.ExactInputParams memory params = ISwapRouterAlgebraV3.ExactInputParams({
            path: _params.encodedPath,
            recipient: _params.to,
            deadline: _params.deadline,
            amountIn: _params.amountIn,
            amountOutMinimum: _params.amountOutMin
        });
        uint256 amountOut = ISwapRouterAlgebraV3(_params.dexRouter).exactInput(params);
        return [_params.amountIn, amountOut, 0];
    }

    function _swapWithCurve(SwapParams memory _params) private returns (uint256[3] memory) {
        // Curve does not check the deadline hence this check is necessary before the swap.
        _require(_params.deadline >= block.timestamp, Errors.SWAP_DEADLINE_PASSED.selector);
        (address[] memory path, address[] memory pools) = abi.decode(_params.encodedPath, (address[], address[]));
        uint256 amountOut = _params.amountIn;

        for (uint256 i; i < path.length - 1; i++) {
            IERC20(path[i]).approve(_params.dexRouter, amountOut);
            amountOut = ICurveRouter(_params.dexRouter).exchange(
                pools[i],
                path[i],
                path[i + 1],
                amountOut,
                i == path.length - 2 ? _params.amountOutMin : 0,
                i == path.length - 2 ? _params.to : address(this)
            );
        }

        return [_params.amountIn, amountOut, 0];
    }

    function _swapWithBalancer(SwapParams memory _params) private returns (uint256[3] memory) {
        (address[] memory path, bytes32[] memory pools, int256[] memory limits) = abi.decode(
            _params.encodedPath,
            (address[], bytes32[], int256[])
        );
        _require(path.length >= 2, Errors.INCORRECT_PATH.selector);
        IERC20(path[0]).approve(_params.dexRouter, _params.amountIn);

        IBalancer.FundManagement memory fundManagement = IBalancer.FundManagement({
            sender: address(this),
            fromInternalBalance: false,
            recipient: payable(_params.to),
            toInternalBalance: false
        });

        if (path.length > 2) {
            (IAsset[] memory assets, IBalancer.BatchSwapStep[] memory steps) = _getBalancerSwapSteps(
                path,
                pools,
                _params.amountIn
            );

            int256[] memory deltas;
            deltas = IBalancer(_params.dexRouter).batchSwap(
                IBalancer.SwapKind.GIVEN_IN,
                steps,
                assets,
                fundManagement,
                limits,
                _params.deadline
            );

            return [_params.amountIn, uint256(deltas[deltas.length - 1] * -1), 0];
        }

        IBalancer.SingleSwap memory singleSwap = IBalancer.SingleSwap({
            poolId: pools[0],
            kind: IBalancer.SwapKind.GIVEN_IN,
            assetIn: IAsset(path[0]),
            assetOut: IAsset(path[1]),
            amount: _params.amountIn,
            userData: "0x"
        });
        uint256 amountOut = IBalancer(_params.dexRouter).swap(
            singleSwap,
            fundManagement,
            _params.amountOutMin,
            _params.deadline
        );
        return [_params.amountIn, amountOut, 0];
    }
}
