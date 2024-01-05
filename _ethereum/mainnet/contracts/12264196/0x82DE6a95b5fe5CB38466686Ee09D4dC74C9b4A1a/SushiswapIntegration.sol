// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "./LiquidityNexusBase.sol";
import "./ISushiswapRouter.sol";
import "./ISushiMasterChef.sol";

contract SushiswapIntegration is LiquidityNexusBase {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    address public constant SLP = address(0x397FF1542f962076d0BFE58eA045FfA2d347ACa0); // Sushiswap USDC/ETH pair
    address public constant ROUTER = address(0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F); // Sushiswap Router2
    address public constant MASTERCHEF = address(0xc2EdaD668740f1aA35E4D8f227fB8E17dcA888Cd);
    address public constant REWARD = address(0x6B3595068778DD592e39A122f4f5a5cF09C90fE2);
    uint256 public constant POOL_ID = 1;
    address[] public pathToETH = new address[](2);
    address[] public pathToUSDC = new address[](2);

    constructor() {
        pathToUSDC[0] = WETH;
        pathToUSDC[1] = USDC;
        pathToETH[0] = USDC;
        pathToETH[1] = WETH;

        IERC20(USDC).approve(ROUTER, uint256(~0));
        IERC20(WETH).approve(ROUTER, uint256(~0));
        IERC20(SLP).approve(ROUTER, uint256(~0));

        IERC20(SLP).approve(MASTERCHEF, uint256(~0));
    }

    /**
     * returns price of ETH in USDC
     */
    function quote(uint256 inETH) public view returns (uint256 outUSDC) {
        (uint112 rUSDC, uint112 rETH, ) = IUniswapV2Pair(SLP).getReserves();
        outUSDC = IUniswapV2Router02(ROUTER).quote(inETH, rETH, rUSDC);
    }

    /**
     * returns price of USDC in ETH
     */
    function quoteInverse(uint256 inUSDC) public view returns (uint256 outETH) {
        (uint112 rUSDC, uint112 rETH, ) = IUniswapV2Pair(SLP).getReserves();
        outETH = IUniswapV2Router02(ROUTER).quote(inUSDC, rUSDC, rETH);
    }

    /**
     * returns ETH amount (in) needed when swapping for requested USDC amount (out)
     */
    function amountInETHForRequestedOutUSDC(uint256 outUSDC) public view returns (uint256 inETH) {
        inETH = IUniswapV2Router02(ROUTER).getAmountsIn(outUSDC, pathToUSDC)[0];
    }

    function _poolSwapExactUSDCForETH(uint256 inUSDC) internal returns (uint256 outETH) {
        if (inUSDC == 0) return 0;

        uint256[] memory amounts =
            IUniswapV2Router02(ROUTER).swapExactTokensForTokens(inUSDC, 0, pathToETH, address(this), block.timestamp); // solhint-disable-line not-rely-on-time
        require(inUSDC == amounts[0], "leftover USDC");
        outETH = amounts[1];
    }

    function _poolSwapExactETHForUSDC(uint256 inETH) internal returns (uint256 outUSDC) {
        if (inETH == 0) return 0;

        uint256[] memory amounts =
            IUniswapV2Router02(ROUTER).swapExactTokensForTokens(
                inETH,
                0,
                pathToUSDC,
                address(this),
                block.timestamp // solhint-disable-line not-rely-on-time
            );
        require(inETH == amounts[0], "leftover ETH");
        outUSDC = amounts[1];
    }

    function _poolAddLiquidityAndStake(uint256 amountETH, uint256 deadline)
        internal
        returns (
            uint256 addedUSDC,
            uint256 addedETH,
            uint256 liquidity
        )
    {
        require(IERC20(WETH).balanceOf(address(this)) >= amountETH, "not enough WETH");
        uint256 quotedUSDC = quote(amountETH);
        require(IERC20(USDC).balanceOf(address(this)) >= quotedUSDC, "not enough free capital");

        (addedETH, addedUSDC, liquidity) = IUniswapV2Router02(ROUTER).addLiquidity(
            WETH,
            USDC,
            amountETH,
            quotedUSDC,
            amountETH,
            0,
            address(this),
            deadline
        );
        require(addedETH == amountETH, "leftover ETH");

        IMasterChef(MASTERCHEF).deposit(POOL_ID, liquidity);
    }

    function _poolUnstakeAndRemoveLiquidity(uint256 liquidity, uint256 deadline)
        internal
        returns (uint256 removedETH, uint256 removedUSDC)
    {
        if (liquidity == 0) return (0, 0);

        IMasterChef(MASTERCHEF).withdraw(POOL_ID, liquidity);

        (removedETH, removedUSDC) = IUniswapV2Router02(ROUTER).removeLiquidity(
            WETH,
            USDC,
            liquidity,
            0,
            0,
            address(this),
            deadline
        );
    }

    function _poolClaimRewards() internal {
        IMasterChef(MASTERCHEF).deposit(POOL_ID, 0);
    }

    function isSalvagable(address token) internal override returns (bool) {
        return super.isSalvagable(token) && token != SLP && token != REWARD;
    }
}
