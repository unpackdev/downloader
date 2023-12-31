// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./IUniswapV2Pair.sol";
import "./IUniswapV2Router01.sol";
import "./ERC20.sol";
import "./SafeTransferLib.sol";

import "./IUniswapV3Pool.sol";
import "./LowGasSafeMath.sol";

import "./IPopsicle.sol";
import "./UniswapV3OneSided.sol";
import "./IBentoBoxV1.sol";
import "./ICurvePool.sol";

/// @notice WETH/USDT Popsicle Leverage Swapper for Ethereum
contract PopsicleWETHUSDTLevSwapper {
    using LowGasSafeMath for uint256;
    using SafeTransferLib for ERC20;

    IBentoBoxV1 public constant DEGENBOX = IBentoBoxV1(0xd96f48665a1410C0cd669A88898ecA36B9Fc2cce);
    IPopsicle public immutable popsicle;

    CurvePool private constant MIM3POOL = CurvePool(0x5a6A4D54456819380173272A5E8E9B9904BdF41B);
    IERC20 private constant MIM = IERC20(0x99D8a9C45b2ecA8864373A26D1459e3Dff1e17F3);

    IERC20 private constant WETH = IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    ERC20 private constant USDT = ERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7);
    IUniswapV2Pair private constant WETHUSDT = IUniswapV2Pair(0x06da0fd433C1A5d7a4faa01111c044910A184553);

    uint256 private constant MIN_USDT_IMBALANCE = 1e6;
    uint256 private constant MIN_WETH_IMBALANCE = 0.0002 ether;

    IUniswapV3Pool private immutable pool;

    constructor(IPopsicle _popsicle) {
        MIM.approve(address(MIM3POOL), type(uint256).max);
        USDT.safeApprove(address(_popsicle), type(uint256).max);
        WETH.approve(address(_popsicle), type(uint256).max);
        pool = IUniswapV3Pool(_popsicle.pool());
        popsicle = _popsicle;
    }

    function swap(
        address recipient,
        uint256 shareToMin,
        uint256 shareFrom
    ) public returns (uint256 extraShare, uint256 shareReturned) {
        (uint256 mimAmount, ) = DEGENBOX.withdraw(MIM, address(this), address(this), 0, shareFrom);

        // MIM -> USDT on Curve MIM3POOL
        MIM3POOL.exchange_underlying(0, 3, mimAmount, 0, address(this));
        uint256 usdtAmount = USDT.balanceOf(address(this)); // account for some amounts left from previous leverages

        // Swap Amount USDT -> WETH to provide optimal 50/50 liquidity
        // Use UniswapV2 pair to avoid changing V3 liquidity balance
        {
            (uint256 reserve0, uint256 reserve1, ) = WETHUSDT.getReserves();
            (uint160 sqrtRatioX, , , , , , ) = pool.slot0();

            (uint256 balance0, uint256 balance1) = UniswapV3OneSided.getAmountsToDeposit(
                UniswapV3OneSided.GetAmountsToDepositParams({
                    sqrtRatioX: sqrtRatioX,
                    tickLower: popsicle.tickLower(),
                    tickUpper: popsicle.tickUpper(),
                    totalAmountIn: usdtAmount,
                    reserve0: reserve0,
                    reserve1: reserve1,
                    minToken0Imbalance: MIN_WETH_IMBALANCE,
                    minToken1Imbalance: MIN_USDT_IMBALANCE,
                    amountInIsToken0: false
                })
            );

            USDT.safeTransfer(address(WETHUSDT), usdtAmount.sub(balance1));
            WETHUSDT.swap(balance0, 0, address(this), new bytes(0));
        }
        (uint256 shares, , ) = popsicle.deposit(WETH.balanceOf(address(this)), USDT.balanceOf(address(this)), address(DEGENBOX));
        (, shareReturned) = DEGENBOX.deposit(IERC20(address(popsicle)), address(DEGENBOX), recipient, shares, 0);
        extraShare = shareReturned - shareToMin;
    }
}
