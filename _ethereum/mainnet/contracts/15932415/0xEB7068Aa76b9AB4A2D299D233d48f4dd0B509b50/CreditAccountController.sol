/// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

import "./ICreditManagerV2.sol";
// import "./IUniswapV3Adapter.sol";
import "./IUniswapV3.sol";
import "./ICurvePool.sol";
import "./MultiCall.sol";

import "./IwstETH.sol";
import "./IstETH.sol";
// import "./IstETH.sol";
// import "./ICurvePool.sol";
import "./IPoolService.sol";
import "./GearboxRegistry.sol";

contract CreditAccountController is GearboxRegistry {
    uint256 public immutable MAX_BPS = 1e4;
    uint256 public CURVE_ETH_STETH_SLIPPAGE = 200;
    uint256 public UNISWAP_ETH_USDC_POOL_SLIPPAGE = 100;
    uint256 public UNISWAP_ETH_FRAX_POOL_SLIPPAGE = 100;
    uint24 public UNISWAP_ETH_USDC_POOL_FEE = 500;
    uint24 public UNISWAP_USDC_FRAX_POOL_FEE = 100;
    uint256 public CURVE_SLIPPAGE_BOUND = 200;
    ICurvePool curvePool =
        ICurvePool(0xDC24316b9AE028F1497c275EB9192a3Ea0f67022);

    constructor(address addressProvider, address creditManager)
        GearboxRegistry(addressProvider, creditManager)
    {}

    function _openCreditAccount(
        uint256 fraxCollateral,
        uint256 ethToBorrow,
        MultiCall memory additionalCall
    ) internal {
        MultiCall[] memory calls = new MultiCall[](2);

        address _creditAccount = address(creditAccount());
        require(_creditAccount == address(0), "CA_ALREADY_EXISTS");
        FRAX.approve(address(creditManager()), fraxCollateral);

        calls[0] = _addCollateralCall(fraxCollateral);
        calls[1] = additionalCall;

        creditFacade().openCreditAccountMulticall(
            ethToBorrow,
            address(this),
            calls,
            0
        );
    }

    function _closeCreditAccount() internal {
        address _creditAccount = address(creditAccount());
        MultiCall[] memory calls = new MultiCall[](1);

        uint256 stETHBal = STETH.balanceOf(_creditAccount);
        if (stETHBal > 1e6) {
            MultiCall[] memory swapCall = new MultiCall[](1);
            uint256 amountOut = priceOracle().convert(
                stETHBal,
                address(STETH),
                address(WETH)
            );
            amountOut = accountOutputSlippage(
                amountOut,
                CURVE_ETH_STETH_SLIPPAGE
            );
            swapCall[0] = (_swapStETHToETHCall(stETHBal, amountOut));

            creditFacade().multicall(swapCall);
        }

        uint256 wethBal = WETH.balanceOf(_creditAccount);
        uint256 wethOwed = _getClosingUnderlyingOwed() + 1;
        /// Line 348 CM
        if (wethOwed > wethBal) {
            uint256 wethRequired = wethOwed - wethBal;

            uint256 fraxNeeded = priceOracle().convert(
                wethRequired,
                address(WETH),
                address(FRAX)
            );
            fraxNeeded = accountInputSlippage(
                fraxNeeded,
                UNISWAP_ETH_FRAX_POOL_SLIPPAGE
            );
            calls[0] = (_swapFRAXToETHCall(wethRequired, fraxNeeded));
        } else if (wethBal > wethOwed) {
            uint256 wethAvailable = wethBal - wethOwed;
            uint256 fraxOut = priceOracle().convert(
                wethAvailable,
                address(WETH),
                address(FRAX)
            );
            fraxOut = accountOutputSlippage(
                fraxOut,
                UNISWAP_ETH_FRAX_POOL_SLIPPAGE
            );
            calls[0] = (_swapETHToFRAXCall(wethAvailable, fraxOut));
        }

        creditFacade().closeCreditAccount(address(this), 0, false, calls);
    }

    function _convertStETHToFrax(uint256 stETHIn)
        internal
        returns (uint256 fraxOut)
    {
        uint256 oldWETHBal = WETH.balanceOf(address(creditAccount()));
        MultiCall[] memory swapCall = new MultiCall[](1);
        uint256 amountOut = priceOracle().convert(
            stETHIn,
            address(STETH),
            address(WETH)
        );
        amountOut = accountOutputSlippage(amountOut, CURVE_ETH_STETH_SLIPPAGE);
        swapCall[0] = (_swapStETHToETHCall(stETHIn, amountOut));

        creditFacade().multicall(swapCall);

        uint256 wethOut = WETH.balanceOf(address(creditAccount())) - oldWETHBal;

        uint256 minFraxOut = priceOracle().convert(
            wethOut,
            address(WETH),
            address(FRAX)
        );
        minFraxOut = accountOutputSlippage(
            fraxOut,
            UNISWAP_ETH_FRAX_POOL_SLIPPAGE
        );

        uint256 oldFraxBal = FRAX.balanceOf(address(creditAccount()));
        swapCall[0] = _swapETHToFRAXCall(wethOut, minFraxOut);
        creditFacade().multicall(swapCall);

        fraxOut = FRAX.balanceOf(address(creditAccount())) - oldFraxBal;
    }

    function _addCollateralCall(uint256 fraxIn)
        internal
        view
        returns (MultiCall memory call)
    {
        call.target = address(creditFacade());
        call.callData = abi.encodeWithSelector(
            ICreditFacade.addCollateral.selector,
            address(this),
            address(FRAX),
            fraxIn
        );
    }

    function _increaseDebtCall(uint256 amountIn)
        internal
        view
        returns (MultiCall memory call)
    {
        call.target = address(creditFacade());
        call.callData = abi.encodeWithSelector(
            ICreditFacade.increaseDebt.selector,
            amountIn
        );
    }

    function _decreaseDebtCall(uint256 amountIn)
        internal
        view
        returns (MultiCall memory call)
    {
        call.target = address(creditFacade());
        call.callData = abi.encodeWithSelector(
            ICreditFacade.decreaseDebt.selector,
            amountIn
        );
    }

    function _getClosingUnderlyingOwed()
        internal
        view
        returns (uint256 amountToPool)
    {
        (uint256 total, ) = creditFacade().calcTotalValue(
            address(creditAccount())
        );

        (
            uint256 borrowedAmount,
            uint256 borrowedAmountWithInterest,

        ) = creditManager().calcCreditAccountAccruedInterest(
                address(creditAccount())
            );

        (amountToPool, , , ) = creditManager().calcClosePayments(
            total,
            ClosureAction.CLOSE_ACCOUNT,
            borrowedAmount,
            borrowedAmountWithInterest
        );
    }

    /// UNISWAP V3 SWAPS

    function _swapETHToFRAXCall(uint256 ethIn, uint256 minFraxOut)
        internal
        view
        returns (MultiCall memory call)
    {
        call = MultiCall({
            target: adapter(UNISWAP_V3_ROUTER),
            callData: abi.encodeWithSelector(
                ISwapRouter.exactInput.selector,
                ISwapRouter.ExactInputParams({
                    path: abi.encodePacked(
                        WETH,
                        UNISWAP_ETH_USDC_POOL_FEE,
                        USDC,
                        UNISWAP_USDC_FRAX_POOL_FEE,
                        FRAX
                    ),
                    recipient: address(creditAccount()),
                    deadline: block.timestamp,
                    amountIn: ethIn,
                    amountOutMinimum: minFraxOut
                })
            )
        });
    }

    function _swapFRAXToETHCall(uint256 ethRequired, uint256 maxFRAXIn)
        internal
        view
        returns (MultiCall memory call)
    {
        call = MultiCall({
            target: adapter(UNISWAP_V3_ROUTER),
            callData: abi.encodeWithSelector(
                ISwapRouter.exactInput.selector,
                ISwapRouter.ExactInputParams({
                    path: abi.encodePacked(
                        FRAX,
                        UNISWAP_USDC_FRAX_POOL_FEE,
                        USDC,
                        UNISWAP_ETH_USDC_POOL_FEE,
                        WETH
                    ),
                    recipient: address(creditAccount()),
                    deadline: block.timestamp,
                    amountIn: maxFRAXIn,
                    amountOutMinimum: ethRequired
                })
            )
        });
    }

    function _swapETHToUSDCCall(uint256 ethIn, uint256 minUSDCOut)
        internal
        view
        returns (MultiCall memory call)
    {
        call = MultiCall({
            target: adapter(UNISWAP_V3_ROUTER),
            callData: abi.encodeWithSelector(
                ISwapRouter.exactInputSingle.selector,
                ISwapRouter.ExactInputSingleParams({
                    tokenIn: address(WETH),
                    tokenOut: address(USDC),
                    fee: UNISWAP_ETH_USDC_POOL_FEE,
                    recipient: address(creditAccount()),
                    deadline: block.timestamp,
                    amountIn: ethIn,
                    amountOutMinimum: minUSDCOut,
                    sqrtPriceLimitX96: 0
                })
            )
        });
    }

    function _swapUSDCToETHCall(uint256 ethRequired, uint256 maxUSDCIn)
        internal
        view
        returns (MultiCall memory call)
    {
        call = MultiCall({
            target: adapter(UNISWAP_V3_ROUTER),
            callData: abi.encodeWithSelector(
                ISwapRouter.exactOutputSingle.selector,
                ISwapRouter.ExactOutputSingleParams({
                    tokenIn: address(USDC),
                    tokenOut: address(WETH),
                    fee: UNISWAP_ETH_USDC_POOL_FEE,
                    recipient: address(creditAccount()),
                    deadline: block.timestamp,
                    amountOut: ethRequired,
                    amountInMaximum: maxUSDCIn,
                    sqrtPriceLimitX96: 0
                })
            )
        });
    }

    /// CURVE SWAPS

    enum CurvePoolIndex {
        ETH,
        STETH
    }

    function _swapETHToStETHCall(uint256 ethAmount, uint256 minStETHAmount)
        internal
        view
        returns (MultiCall memory call)
    {
        uint256 stETHPriceCurve = curvePool.get_dy(0, 1, ethAmount);

        uint256 stETHPriceLido = ethAmount - 1;

        if (stETHPriceCurve > stETHPriceLido) {
            //curve swap
            call = MultiCall({
                target: adapter(CURVE_STETH_GATEWAY),
                callData: abi.encodeWithSelector(
                    ICurvePool.exchange.selector,
                    CurvePoolIndex.ETH, // i
                    CurvePoolIndex.STETH, // j
                    ethAmount, // dx
                    minStETHAmount // min_dy
                )
            });
        } else {
            //lido deposit
            call = MultiCall({
                target: adapter(LIDO_STETH_GATEWAY),
                callData: abi.encodeWithSelector(
                    IstETH.submit.selector,
                    ethAmount
                )
            });
        }
    }

    function _swapStETHToETHCall(uint256 stETHAmount, uint256 minETHAmount)
        internal
        view
        returns (MultiCall memory call)
    {
        call = MultiCall({
            target: adapter(CURVE_STETH_GATEWAY),
            callData: abi.encodeWithSelector(
                ICurvePool.exchange.selector,
                CurvePoolIndex.STETH, // i
                CurvePoolIndex.ETH, // j
                stETHAmount, // dx
                minETHAmount // min_dy
            )
        });
    }

    /// Helper Methods

    function accountOutputSlippage(uint256 amount, uint256 bps)
        internal
        pure
        returns (uint256)
    {
        return (amount * (MAX_BPS - bps)) / MAX_BPS;
    }

    function accountInputSlippage(uint256 amount, uint256 bps)
        internal
        pure
        returns (uint256)
    {
        return (amount * (MAX_BPS + bps)) / MAX_BPS;
    }

    function positionInWantToken() public view returns (uint256 totalEquity) {
        if (isCreditAccountOpen()) {
            (, , uint256 borrowedAmountAndFeesAndInterest) = creditManager()
                .calcCreditAccountAccruedInterest(address(creditAccount()));

            uint256 totalBorrowedETHInWantToken = priceOracle().convert(
                borrowedAmountAndFeesAndInterest,
                address(WETH),
                address(FRAX)
            );

            uint256 totalstETHInWantToken = priceOracle().convert(
                getStETHPriceInETH(STETH.balanceOf(address(creditAccount()))),
                address(WETH),
                address(FRAX)
            );

            totalEquity =
                FRAX.balanceOf(address(creditAccount())) +
                totalstETHInWantToken -
                totalBorrowedETHInWantToken;
        }
    }

    function healthFactor()
        public
        view
        creditAccountRequired
        returns (uint256)
    {
        return
            creditFacade().calcCreditAccountHealthFactor(
                address(creditAccount())
            );
    }

    function getLeverage() public view returns (uint256 leverage) {
        uint256 totalEquity = positionInWantToken();

        (, , uint256 borrowedAmountAndFeesAndInterest) = creditManager()
            .calcCreditAccountAccruedInterest(address(creditAccount()));

        uint256 totalBorrowedETHInWantToken = priceOracle().convert(
            borrowedAmountAndFeesAndInterest,
            address(WETH),
            address(FRAX)
        );
        leverage = (totalBorrowedETHInWantToken * MAX_BPS) / totalEquity;
    }

    function getBorrowingRate() public view returns (uint256 borrowRate) {
        IPoolService ethPool = IPoolService(creditManager().pool());
        borrowRate = ethPool.borrowAPY_RAY();
    }

    function getBalances()
        public
        view
        returns (
            uint256 fraxBalance,
            uint256 ethDebtBalance,
            uint256 stETHbalance
        )
    {
        if (isCreditAccountOpen() == true) {
            fraxBalance = FRAX.balanceOf(address(creditAccount()));

            (, , ethDebtBalance) = creditManager()
                .calcCreditAccountAccruedInterest(address(creditAccount()));

            stETHbalance = STETH.balanceOf(address(creditAccount()));
        }
    }

    function getPrices()
        public
        view
        returns (
            uint256 ethPrice,
            uint256 stETHPrice,
            uint256 stETHPriceOnCurve
        )
    {
        uint256 stETHBalance = STETH.balanceOf(address(creditAccount()));
        ethPrice = priceOracle().convertToUSD(1e18, address(WETH));
        stETHPrice = priceOracle().convertToUSD(1e18, address(STETH));
        stETHPriceOnCurve =
            (curvePool.get_dy(1, 0, stETHBalance) * MAX_BPS) /
            stETHBalance;
    }

    /// @notice Calculates ETH amount for stETH based on curvePool
    /// @param amountOfStETH The amount of stETH tokens to deposit
    function getStETHPriceInETH(uint256 amountOfStETH)
        public
        view
        returns (uint256 amountOut)
    {
        uint256 oracleAmount = priceOracle().convert(
            amountOfStETH,
            address(STETH),
            address(WETH)
        );
        uint256 curveAmount = curvePool.get_dy(1, 0, amountOfStETH);
        uint256 boundAmount = (oracleAmount *
            (MAX_BPS - CURVE_SLIPPAGE_BOUND)) / MAX_BPS;
        amountOut = curveAmount < boundAmount ? boundAmount : curveAmount;
    }

    /// @notice Gives the min and max leverage the cm account can operate on.
    function getCMLeverageLimits()
        public
        view
        returns (uint256 minLeverage, uint256 maxLeverage)
    {
        (uint256 minAmountBorrow, uint256 maxAmountBorrow) = creditFacade()
            .limits();
        uint256 minAmount = priceOracle().convert(
            minAmountBorrow,
            address(WETH),
            address(FRAX)
        );
        uint256 maxAmount = priceOracle().convert(
            maxAmountBorrow,
            address(WETH),
            address(FRAX)
        );
        uint256 totalEquity = positionInWantToken();
        minLeverage = (minAmount * MAX_BPS) / totalEquity;

        minLeverage = (minLeverage * (MAX_BPS + 1000)) / MAX_BPS; // added 10% buffer
        maxLeverage = (maxAmount * MAX_BPS) / totalEquity;
        maxLeverage = (maxLeverage * (MAX_BPS - 1000)) / MAX_BPS; // removed 10% buffer
    }

    function _setSlippageBound(uint256 slippage)
        internal
        checkSlippage(slippage)
    {
        CURVE_SLIPPAGE_BOUND = slippage;
    }

    function _setCurveSwapSlippage(uint256 slippage)
        internal
        checkSlippage(slippage)
    {
        CURVE_ETH_STETH_SLIPPAGE = slippage;
    }

    function _setUniETHSlippage(uint256 slippage)
        internal
        checkSlippage(slippage)
    {
        UNISWAP_ETH_USDC_POOL_SLIPPAGE = slippage;
    }

    function _setUniFRAXSlippage(uint256 slippage)
        internal
        checkSlippage(slippage)
    {
        UNISWAP_ETH_FRAX_POOL_SLIPPAGE = slippage;
    }

    modifier checkSlippage(uint256 _slippage) {
        require(_slippage < MAX_BPS / 10, "ILLEGAL_SLIPPAGE");
        _;
    }

    function isCreditAccountOpen() public view returns (bool) {
        return !(address(creditAccount()) == address(0));
    }

    modifier creditAccountRequired() {
        require(isCreditAccountOpen(), "CREDIT_ACCOUNT_NOT_FOUND");
        _;
    }
}
