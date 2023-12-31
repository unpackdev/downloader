// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./Math.sol";
import "./IERC20.sol";
import "./Ownable.sol";
import "./ITimeIsUp.sol";
import "./IHelperBase.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router02.sol";
import "./IUniswapV2Pair.sol";
import "./IWETH.sol";

contract Helper is Ownable, IHelperBase {
    using Math for uint256;

    bool internal immutable hasAlternativeSwap;

    bool internal isInternal;
    bool internal isRunningArbitrage;
    bool internal swapSuccessful;

    enum Operation {
        ETH_TO_TUP_INTERNAL_TUP_TO_ETH_EXTERNAL,
        ETH_TO_TUP_EXTERNAL_TUP_TO_ETH_INTERNAL
    }

    Operation internal operation;

    IUniswapV2Router02 internal router;
    IUniswapV2Factory internal factory;
    ITimeIsUp internal tup;

    address internal _pairTupEth;

    uint256 internal constant FACTOR = 10 ** 18;
    uint256 internal constant ARBITRAGE_RATE = 500;
    uint256 internal constant SWAP_FEE = 100;

    uint256[22] internal rangesWETH = [
        50_000_000 ether,
        10_000_000 ether,
        5_000_000 ether,
        1_000_000 ether,
        500_000 ether,
        100_000 ether,
        50_000 ether,
        10_000 ether,
        5_000 ether,
        1_000 ether,
        500 ether,
        100 ether,
        50 ether,
        10 ether,
        5 ether,
        1 ether,
        0.5 ether,
        0.1 ether,
        0.05 ether,
        0.01 ether,
        0.005 ether,
        0.001 ether
    ];

    modifier fromTup() {
        require(msg.sender == address(tup), "Helper: only TUP token contract can call this function");
        _;
    }

    modifier internalOnly() {
        require(isInternal, "Helper: sorry buddy but you do not have access to this function");
        _;
    }

    modifier adjustInternalCondition() {
        isInternal = true;
        _;
        isInternal = false;
    }

    modifier runningArbitrage() {
        if (!isRunningArbitrage) {
            isRunningArbitrage = true;
            _;
            isRunningArbitrage = false;
        }
    }

    constructor(
        address _addressProvider,
        address _exchangeRouterAddress,
        address _tupTokenAddress,
        bool _hasAlternativeSwap,
        address _owner
    ) {
        router = IUniswapV2Router02(_exchangeRouterAddress);
        factory = IUniswapV2Factory(router.factory());
        tup = ITimeIsUp(payable(_tupTokenAddress));
        hasAlternativeSwap = _hasAlternativeSwap;
        if (_owner != msg.sender)
            transferOwnership(_owner);
    }

    function _calculateFee(uint256 amount) internal virtual returns (uint256) {
        return amount + amount.mulDiv(SWAP_FEE, 10_000);
    }

    function _startTraditionalSwap(address asset, uint256 amount) internal virtual returns (bool) {
        return false;
    }

    function _startAlternativeSwap(uint256 amountIn, uint256 amountOut) internal returns (bool) {
        address weth = router.WETH();
        swapSuccessful = false;
        IUniswapV2Pair pair = IUniswapV2Pair(_pairTupEth);
        if (operation == Operation.ETH_TO_TUP_EXTERNAL_TUP_TO_ETH_INTERNAL) {
            uint256 amount0Out = address(tup) == pair.token0() ? amountOut : 0;
            uint256 amount1Out = address(tup) == pair.token1() ? amountOut : 0;
            try pair.swap(amount0Out, amount1Out, address(this), bytes(abi.encode(address(tup), amountOut))) {
                return swapSuccessful;
            } catch {
                return swapSuccessful;
            }
        } else {
            // ETH_TO_TUP_INTERNAL_TUP_TO_ETH_EXTERNAL
            uint256 amount0Out = weth == pair.token0() ? amountIn : 0;
            uint256 amount1Out = weth == pair.token1() ? amountIn : 0;
            try pair.swap(amount0Out, amount1Out, address(this), bytes(abi.encode(weth, amountIn))) {
                return swapSuccessful;
            } catch {
                return swapSuccessful;
            }
        }
    }

    receive() external payable { }

    fallback() external payable {
        require(msg.data.length == 0);
    }

    function _commonCall(address sender, bytes calldata data) internal {
        if (msg.sender == _pairTupEth) {
            if (sender == address(this)) {
                // Operation.ETH_TO_TUP_EXTERNAL_TUP_TO_ETH_INTERNAL
                (address tokenToBorrow, uint256 amountToBorrow) = abi.decode(data, (address, uint256));
                if (tokenToBorrow == address(tup)) {
                    // 1. TUP -> ETH (Internal)
                    try tup.sell(amountToBorrow) {
                        address[] memory path = new address[](2);
                        path[0] = router.WETH();
                        path[1] = address(tup);
                        uint256[] memory amountRequired = router.getAmountsIn(amountToBorrow, path);
                        IWETH(path[0]).deposit{ value: amountRequired[0] }();
                        // 2. ETH -> TUP (External)
                        IERC20(path[0]).transfer(msg.sender, amountRequired[0]);
                        tup.receiveProfit{ value: address(this).balance }();
                        swapSuccessful = true;
                    } catch {
                        swapSuccessful = false;
                        return;
                    }
                } else {
                    // 1. ETH -> TUP (Internal)
                    address weth = router.WETH();
                    IWETH(weth).withdraw(amountToBorrow);
                    try tup.buy{ value: amountToBorrow }() {
                        address[] memory path = new address[](2);
                        path[0] = address(tup);
                        path[1] = weth;
                        uint256[] memory amountRequired = router.getAmountsIn(amountToBorrow, path);
                        // 2. TUP -> ETH (External)
                        IERC20(path[0]).transfer(msg.sender, amountRequired[0]);
                        try tup.returnNative{ value: address(this).balance }() { // We return the pool amount to the contract here
                            try tup.sell(tup.balanceOf(address(this))) {
                                tup.receiveProfit{ value: address(this).balance }();
                                swapSuccessful = true;
                            } catch {
                                swapSuccessful = false;
                                return;
                            }
                        } catch { 
                            swapSuccessful = false;
                            return;
                        }
                    } catch {
                        swapSuccessful = false;
                        return;
                    }
                }
            }
        } else {
            swapSuccessful = false;
            return;
        }
    }

    function _createPair(address asset01, address asset02) internal returns (address pair) {
        pair = factory.getPair(asset01, asset02);
        if (pair == address(0) && asset01 != address(0) && asset02 != address(0)) {
            try factory.createPair(asset01, asset02) returns (address p) {
                pair = p;
            } catch {
                revert();
            }
        }
        return pair;
    }

    function _performOperation(address asset, uint256 amount) internal returns (bool) {
        if (operation == Operation.ETH_TO_TUP_INTERNAL_TUP_TO_ETH_EXTERNAL) {
            IWETH(asset).withdraw(amount); // assumming asset == weth
            try tup.buy{ value: amount }() {
                address[] memory path = new address[](2);
                path[0] = address(tup);
                path[1] = asset;
                uint256 tupAmount = tup.balanceOf(address(this));
                tup.approve(address(router), tupAmount);
                try router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                    tupAmount,
                    0, // amount,
                    path,
                    address(this),
                    block.timestamp + 300
                ) {
                    return true;
                } catch {
                    return false;
                }
            } catch {
                return false;
            }
        } else {
            address[] memory path = new address[](2);
            path[0] = asset;
            path[1] = address(tup);
            IERC20(asset).approve(address(router), amount);
            try router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                amount,
                0, //tup.queryAmountInternalLP(amount),
                path,
                address(this),
                block.timestamp + 300
            ) {
                uint256 tupAmount = tup.balanceOf(address(this));
                try tup.sell(tupAmount) {
                    IWETH(asset).deposit{ value: address(this).balance }();
                    return true;
                } catch {
                    return false;
                }
            } catch {
                return false;
            }
        }
    }

    /**
     * @dev Add liquidity for the TUP/ETH pair LP in third party exchange (based on UniswapV2)
     *
     */
    function addLiquidityNative(uint256 tupAmount) external payable fromTup returns (bool) {
        tup.approve(address(router), tupAmount);
        // add liquidity for the TUP/ETH pair
        try router.addLiquidityETH{ value: msg.value }(
            address(tup),
            tupAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            address(0),
            block.timestamp + 300
        ) {
            return true;
        } catch {
            tup.returnNative{ value: msg.value }();
            return false;
        }
    }

    function checkAndPerformArbitrage() external virtual runningArbitrage fromTup adjustInternalCondition returns (bool) {
        address weth = router.WETH();

        address pair = factory.getPair(address(tup), weth);
        uint256 balanceInternalNative = tup.poolBalance();
        uint256 balanceExternalNative = IERC20(weth).balanceOf(pair);
        uint256 balanceInternalTUP = tup.balanceOf(address(tup));
        uint256 balanceExternalTUP = tup.balanceOf(pair);

        if (balanceInternalNative == 0 || balanceExternalNative == 0) {
            return false;
        }

        uint256 rateInternal = balanceInternalTUP.mulDiv(FACTOR, balanceInternalNative);
        uint256 rateExternal = balanceExternalTUP.mulDiv(FACTOR, balanceExternalNative);

        if (rateExternal == 0 || rateInternal == 0) {
            return false;
        }

        bool shouldPerformArbitrage = (rateExternal > rateInternal)
            ? (rateExternal - rateInternal).mulDiv(10_000, rateExternal) >= ARBITRAGE_RATE
            : (rateInternal - rateExternal).mulDiv(10_000, rateInternal) >= ARBITRAGE_RATE;

        return (shouldPerformArbitrage ? _performArbitrage() : false);
    }

    function _performArbitrage() internal returns (bool success) {
        address weth = router.WETH();

        address[] memory assets_01 = new address[](2);
        assets_01[0] = weth;
        assets_01[1] = address(tup);
        address[] memory assets_02 = new address[](2);
        assets_02[0] = address(tup);
        assets_02[1] = weth;

        uint256[] memory amountOutExternal;
        uint256 amountOutInternal;

        address pair = factory.getPair(address(tup), weth);
        uint256 balanceInternalNative = tup.poolBalance();
        uint256 balanceExternalNative = IERC20(weth).balanceOf(pair);
        uint256 balanceInternalTUP = tup.balanceOf(address(tup));
        uint256 balanceExternalTUP = tup.balanceOf(pair);

        // getAmountsIn (amountOut, path) --> Given an amountOut value of path[1] token, it will tell us how many path[0] tokens we send
        // getAmountsOut(amountIn,  path) --> Given an amountIn  value of path[0] token, it will tell us how many path[1] tokens we receive
        for (uint256 i = 0; i < rangesWETH.length; i++) {
            amountOutExternal = router.getAmountsOut(rangesWETH[i], assets_01);
            amountOutInternal = tup.queryNativeAmount(amountOutExternal[1]);
            uint256 totalWithFee = _calculateFee(rangesWETH[i]);
            if (amountOutInternal <= totalWithFee) {
                amountOutInternal = tup.queryAmountOptimal(rangesWETH[i]);
                amountOutExternal = router.getAmountsOut(amountOutInternal, assets_02);
                if (amountOutExternal[1] > totalWithFee) {
                    // perform arbitrage here - Option #1 - Buy TUP LP Internal and Sell TUP LP External
                    if (balanceExternalNative >= amountOutExternal[1] && balanceInternalTUP >= amountOutInternal) {
                        operation = Operation.ETH_TO_TUP_INTERNAL_TUP_TO_ETH_EXTERNAL;
                        if (!hasAlternativeSwap) {
                            success = _startTraditionalSwap(weth, rangesWETH[i]);
                            if (!success) {
                                success = _startAlternativeSwap(rangesWETH[i], amountOutInternal);
                            }
                        } else {
                            success = _startAlternativeSwap(rangesWETH[i], amountOutInternal);
                        }
                        if (success) {
                            break;
                        }
                    }
                }
            } else {
                // perform arbitrage here - Option #2 - Buy TUP LP External and Sell TUP LP Internal
                if (balanceInternalNative >= amountOutInternal && balanceExternalTUP >= amountOutExternal[1]) {
                    operation = Operation.ETH_TO_TUP_EXTERNAL_TUP_TO_ETH_INTERNAL;
                    if (!hasAlternativeSwap) {
                        success = _startTraditionalSwap(weth, rangesWETH[i]);
                        if (!success) {
                            success = _startAlternativeSwap(rangesWETH[i], amountOutExternal[1]);
                        }
                    } else {
                        success = _startAlternativeSwap(rangesWETH[i], amountOutExternal[1]);
                    }
                    if (success) {
                        break;
                    }
                }
            }
        }
        return success;
    }

    function pancakeCall(address _sender, uint256 _amount0, uint256 _amount1, bytes calldata _data) external {
        _commonCall(_sender, _data);
    }

    function pairTupEth() external view returns (address) {
        return _pairTupEth;
    }

    function uniswapV2Call(address _sender, uint256 _amount0, uint256 _amount1, bytes calldata _data) external {
        _commonCall(_sender, _data);
    }

    function queryRate() external view fromTup returns (uint256) {
        address weth = router.WETH();
        uint256 ethBalance = IERC20(weth).balanceOf(_pairTupEth);
        return (ethBalance == 0) ? FACTOR : tup.balanceOf(_pairTupEth).mulDiv(FACTOR, ethBalance);
    }

    function queryPoolAddress() external view virtual returns (address) {
        return address(0);
    }

    function setTup(address tupAddress) external virtual onlyOwner {
        tup = ITimeIsUp(payable(tupAddress));
        _pairTupEth = _createPair(address(tup), router.WETH());
    }
}
