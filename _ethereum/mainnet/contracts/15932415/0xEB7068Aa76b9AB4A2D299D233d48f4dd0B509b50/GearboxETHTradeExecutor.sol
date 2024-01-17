/// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

import "./MultiCall.sol";

import "./IVault.sol";
import "./BaseTradeExecutor.sol";
import "./CreditAccountController.sol";

contract GearboxETHTradeExecutor is BaseTradeExecutor, CreditAccountController {
    constructor(
        address _vault,
        address _creditManager,
        address _addressProvider
    )
        BaseTradeExecutor(_vault)
        CreditAccountController(_addressProvider, _creditManager)
    {}

    /// @notice Emitted after new credit account is opened.
    /// @param account The address of creditAccount.
    /// @param fraxIn The amount of underlying tokens that were deposited.
    event OpenCreditAccount(address indexed account, uint256 fraxIn);

    function openCreditAccount(uint256 fraxIn, uint256 leverage)
        external
        onlyKeeper
    {
        uint256 ethValue = priceOracle().convert(
            (fraxIn * leverage) / MAX_BPS,
            address(FRAX),
            address(WETH)
        );

        MultiCall memory call = CreditAccountController._swapETHToStETHCall(
            ethValue,
            ethValue - 1
        );

        CreditAccountController._openCreditAccount(fraxIn, ethValue, call);
        emit OpenCreditAccount(address(creditAccount()), fraxIn);
    }

    /// @notice Emitted after colllateral is deposited into credit account.
    /// @param fraxIn The amount of underlying tokens that were deposited.
    event IncreaseCollateral(uint256 fraxIn);

    function increaseCollateral(uint256 fraxIn)
        external
        onlyKeeper
        creditAccountRequired
    {
        FRAX.approve(address(creditManager()), fraxIn);
        MultiCall[] memory calls = new MultiCall[](1);
        calls[0] = CreditAccountController._addCollateralCall(fraxIn);
        creditFacade().multicall(calls);
        emit IncreaseCollateral(fraxIn);
    }

    /// @notice Emitted when leverage is updated.
    /// @param oldLeverage The value of old leverage.
    /// @param newLeverage The value of new leverage.
    event UpdatedLeverage(uint256 oldLeverage, uint256 newLeverage);

    function setLeverage(uint256 newLeverage) external onlyKeeper {
        uint256 currentLeverage = CreditAccountController.getLeverage();
        uint256 totalEquity = CreditAccountController.positionInWantToken();
        bool toBorrow = newLeverage > currentLeverage;

        if (toBorrow) {
            uint256 borrowedInWant = (totalEquity *
                (newLeverage - currentLeverage)) / MAX_BPS;
            uint256 ethIn = priceOracle().convert(
                borrowedInWant,
                address(FRAX),
                address(WETH)
            );
            increaseLeverage(ethIn);
        } else {
            uint256 borrowOutWant = (totalEquity *
                (currentLeverage - newLeverage)) / MAX_BPS;
            uint256 ethOut = priceOracle().convert(
                borrowOutWant,
                address(FRAX),
                address(WETH)
            );

            decreaseLeverage(ethOut);
        }

        emit UpdatedLeverage(currentLeverage, newLeverage);
    }

    /// @notice Emitted when more funds are borrowed.
    /// @param borrowedFunds The value of funds borrowed in eth .
    event DebtIncrease(uint256 borrowedFunds);

    function increaseLeverage(uint256 ethIn)
        public
        onlyKeeper
        creditAccountRequired
    {
        MultiCall[] memory calls = new MultiCall[](2);
        calls[0] = CreditAccountController._increaseDebtCall(ethIn);
        uint256 amountOut = priceOracle().convert(
            ethIn,
            address(WETH),
            address(STETH)
        );
        amountOut = accountOutputSlippage(amountOut, CURVE_ETH_STETH_SLIPPAGE);
        calls[1] = CreditAccountController._swapETHToStETHCall(
            ethIn,
            amountOut - 1
        );
        creditFacade().multicall(calls);
        emit DebtIncrease(ethIn);
    }

    /// @notice Emitted when more funds are payed back.
    /// @param payedFunds The value of funds payed back in eth .
    event DebtDecrease(uint256 payedFunds);

    function decreaseLeverage(uint256 ethOut)
        public
        onlyKeeper
        creditAccountRequired
    {
        uint256 wethBal = WETH.balanceOf(address(creditAccount()));
        MultiCall[] memory calls = new MultiCall[](1);
        uint256 amountIn = priceOracle().convert(
            ethOut,
            address(WETH),
            address(STETH)
        );
        amountIn = accountInputSlippage(amountIn, CURVE_ETH_STETH_SLIPPAGE);
        calls[0] = CreditAccountController._swapStETHToETHCall(
            amountIn,
            ethOut
        );
        creditFacade().multicall(calls);

        uint256 swapResult = WETH.balanceOf(address(creditAccount())) - wethBal;

        calls[0] = CreditAccountController._decreaseDebtCall(swapResult);

        creditFacade().multicall(calls);

        emit DebtDecrease(swapResult);
    }

    function multicall(MultiCall[] memory calls) external onlyKeeper {
        creditFacade().multicall(calls);
    }

    /// @notice Emitted after new credit account is opened.
    /// @param account The address of creditAccount.
    event CloseCreditAccount(address indexed account);

    function closeCreditAccount() external onlyKeeper creditAccountRequired {
        emit CloseCreditAccount(address(creditAccount()));
        CreditAccountController._closeCreditAccount();
    }

    function closeCreditAccountManual(
        uint256 skipTokenMask,
        bool convertWETH,
        MultiCall[] memory additionalCalls
    ) external onlyKeeper creditAccountRequired {
        creditFacade().closeCreditAccount(
            address(this),
            skipTokenMask,
            convertWETH,
            additionalCalls
        );
    }

    /// @notice Emitted when yield is claimed.
    /// @param yield The amount of yield that is claimed.
    event Claim(uint256 yield);

    function claimYield() external onlyKeeper {
        // yieldAccumulated = stETH value - eth debt
        uint256 totalstETHInWantToken = priceOracle().convert(
            STETH.balanceOf(address(creditAccount())),
            address(STETH),
            address(FRAX)
        );
        (, , uint256 borrowedAmountAndFeesAndInterest) = creditManager()
            .calcCreditAccountAccruedInterest(address(creditAccount()));

        uint256 totalBorrowedETHInWantToken = priceOracle().convert(
            borrowedAmountAndFeesAndInterest,
            address(WETH),
            address(FRAX)
        );

        uint256 yieldAccumulated = totalstETHInWantToken >
            totalBorrowedETHInWantToken
            ? (totalstETHInWantToken - totalBorrowedETHInWantToken)
            : 0;
        if (yieldAccumulated > 0) {
            uint256 yieldAccumulatedInStETH = priceOracle().convert(
                yieldAccumulated,
                address(FRAX),
                address(STETH)
            );

            // convert stETH to wantToken via swap.
            uint256 claimedYield = CreditAccountController._convertStETHToFrax(
                yieldAccumulatedInStETH
            );
            emit Claim(claimedYield);
        }
    }

    function totalFunds()
        external
        view
        returns (uint256 posValue, uint256 lastUpdatedBlock)
    {
        posValue =
            FRAX.balanceOf(address(this)) +
            CreditAccountController.positionInWantToken();
        return (posValue, block.number);
    }

    /// @notice event emitted when slippage is updated
    event UpdatedSlippage(
        uint256 indexed oldSlippage,
        uint256 indexed newSlippage,
        uint256 indexed index
    );

    /// @notice Keeper function to set max slippage acceptable for accounting funds.
    /// @param _slippage Max accepted slippage during pricing of funds
    function setSlippageBound(uint256 _slippage) external onlyGovernance {
        uint256 oldSlippage = CreditAccountController.CURVE_SLIPPAGE_BOUND;

        CreditAccountController._setSlippageBound(_slippage);
        emit UpdatedSlippage(oldSlippage, _slippage, 0);
    }

    /// @notice Keeper function to set max accepted slippage of curve swaps
    /// @param _slippage Max accepted slippage during taking leveraged position
    function setCurveSwapSlippage(uint256 _slippage) external onlyGovernance {
        uint256 oldSlippage = CreditAccountController.CURVE_ETH_STETH_SLIPPAGE;

        CreditAccountController._setCurveSwapSlippage(_slippage);
        emit UpdatedSlippage(oldSlippage, _slippage, 1);
    }

    /// @notice Keeper function to set max accepted slippage of eth usdc swap.
    /// @param _slippage Max accepted slippage during harvesting
    function setUniETHSlippage(uint256 _slippage) external onlyGovernance {
        uint256 oldSlippage = CreditAccountController
            .UNISWAP_ETH_USDC_POOL_SLIPPAGE;

        CreditAccountController._setUniETHSlippage(_slippage);
        emit UpdatedSlippage(oldSlippage, _slippage, 2);
    }

    /// @notice Keeper function to set max accepted slippage of eth frax swap.
    /// @param _slippage Max accepted slippage during closing account
    function setUniFRAXSlippage(uint256 _slippage) external onlyGovernance {
        uint256 oldSlippage = CreditAccountController
            .UNISWAP_ETH_FRAX_POOL_SLIPPAGE;

        CreditAccountController._setUniETHSlippage(_slippage);
        emit UpdatedSlippage(oldSlippage, _slippage, 3);
    }
}
