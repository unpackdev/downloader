// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.7.6;
pragma abicoder v2;

import "ISwapRouter.sol";
import "Ownable.sol";
import "IERC20.sol";
import "SafeERC20.sol";
import "ReentrancyGuard.sol";

import "IApeFinance.sol";

interface ICurvePool {
    function coins(uint256 i) external view returns (address);
    function exchange(int128 i, int128 j, uint256 dx, uint256 min) external returns (uint256);
}

contract ApeUSDLiquidator is ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;

    ISwapRouter public constant swapRouter = ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);
    uint24 public constant poolFee03 = 3000; // 0.3%
    uint24 public constant poolFee005 = 500; // 0.05%
    address public constant WETH9 = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address public constant FRAX = 0x853d955aCEf822Db058eb8505911ED77F175b99e;

    ICurvePool public constant curvePool = ICurvePool(0x1977870a4c18a728C19Dd4eB6542451DF06e0A4b);

    IApeFinance public immutable apeAPE;
    IApeFinance public immutable apeApeUSD;
    IERC20 public immutable ape;
    IERC20 public immutable apeUSD;

    constructor(
        IApeFinance _apeAPE,
        IApeFinance _apeApeUSD
    ) {
        apeAPE = _apeAPE;
        apeApeUSD = _apeApeUSD;

        ape = IERC20(_apeAPE.underlying());
        apeUSD = IERC20(_apeApeUSD.underlying());
    }

    function liquidate(address[] calldata borrower, uint256[] calldata repayAmount, uint256 totalBorrow) external nonReentrant() {
        apeApeUSD.borrow(payable(address(this)), totalBorrow);
        apeUSD.approve(address(apeApeUSD), totalBorrow*2);

        for (uint256 i = 0; i < borrower.length; i++) {
            apeApeUSD.liquidateBorrow(borrower[i], repayAmount[i], address(apeAPE));
        }

        apeAPE.redeem(payable(address(this)), apeAPE.balanceOf(address(this)), 0);
        uint256 fraxAmount = swapOnUniswap(ape.balanceOf(address(this)));
        swapOnCurve(fraxAmount);

        apeApeUSD.repayBorrow(address(this), uint256(-1));
        uint256 profit = apeUSD.balanceOf(address(this));
        if (profit > 0) {
            apeUSD.safeTransfer(owner(), profit);
        }
    }

    function swapOnUniswap(uint256 amountIn) internal returns (uint256 amountOut) {
        ape.approve(address(swapRouter), amountIn);

        ISwapRouter.ExactInputParams memory params =
            ISwapRouter.ExactInputParams({
                path: abi.encodePacked(address(ape), poolFee03, WETH9, poolFee005, USDC, poolFee005, FRAX),
                recipient: address(this),
                deadline: block.timestamp,
                amountIn: amountIn,
                amountOutMinimum: 0
            });

        amountOut = swapRouter.exactInput(params);
    }

    function swapOnCurve(uint256 amountIn) internal returns (uint256 amountOut) {
        IERC20(FRAX).approve(address(curvePool), amountIn);

        if (curvePool.coins(0) == address(FRAX)) {
            amountOut = curvePool.exchange(0, 1, amountIn, 0);
        }
        else {
            amountOut = curvePool.exchange(1, 0, amountIn, 0);
        }
    }
}
