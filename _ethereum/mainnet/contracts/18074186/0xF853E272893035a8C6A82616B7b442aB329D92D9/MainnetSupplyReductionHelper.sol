// SPDX-License-Identifier: CC0-1.0

pragma solidity 0.8.15;

import "./INonfungiblePositionManager.sol";

interface IBobToken {
    function balanceOf(address user) external view returns (uint256);
    function approve(address to, uint256 amount) external;
    function burn(uint256 amount) external;
}

interface IBobSwap {
    function admin() external view returns (address);
    function reclaim(address to, uint256 amount) external;
    function give(address token, uint256 amount) external;
    function farm(address token) external;
    function setCollateralFees(address token, uint64 inFee, uint64 outFee) external;
}

contract MainnetSupplyReductionHelper {
    address constant positionManager = address(0xC36442b4a4522E871399CD717aBDD847Ab11FE88);
    uint256 constant tokenId1 = uint256(326624); // USDC/BOB 0.05%
    uint256 constant tokenId2 = uint256(345121); // USDC/BOB 0.01%
    uint256 constant tokenId3 = uint256(496745); // USDT/BOB 0.01%
    address constant bob = address(0xB0B195aEFA3650A6908f15CdaC7D92F8a5791B0B);
    address constant usdc = address(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    address constant usdt = address(0xdAC17F958D2ee523a2206206994597C13D831ec7);
    address constant dai = address(0x6B175474E89094C44Da98b954EedeAC495271d0F);
    address constant bobSwap = address(0x15729Ac1795Fa02448a55D206005dC1914144a9F);

    function step1() external {
        step2();

        (,,,,,,, uint128 liquidity1,,,,) = INonfungiblePositionManager(positionManager).positions(tokenId1);
        (,,,,,,, uint128 liquidity2,,,,) = INonfungiblePositionManager(positionManager).positions(tokenId2);
        (,,,,,,, uint128 liquidity3,,,,) = INonfungiblePositionManager(positionManager).positions(tokenId3);

        (uint256 amountUSDC1, uint256 amountBOB1) = INonfungiblePositionManager(positionManager).decreaseLiquidity(
            INonfungiblePositionManager.DecreaseLiquidityParams(tokenId1, liquidity1, 0, 0, block.timestamp)
        );
        (uint256 amountUSDC2, uint256 amountBOB2) = INonfungiblePositionManager(positionManager).decreaseLiquidity(
            INonfungiblePositionManager.DecreaseLiquidityParams(tokenId2, liquidity2 * 5 / 6, 0, 0, block.timestamp)
        );
        (uint256 amountBOB3, uint256 amountUSDT) = INonfungiblePositionManager(positionManager).decreaseLiquidity(
            INonfungiblePositionManager.DecreaseLiquidityParams(tokenId3, liquidity3, 0, 0, block.timestamp)
        );

        INonfungiblePositionManager(positionManager).collect(
            INonfungiblePositionManager.CollectParams(tokenId1, address(this), type(uint128).max, type(uint128).max)
        );
        INonfungiblePositionManager(positionManager).collect(
            INonfungiblePositionManager.CollectParams(tokenId2, address(this), type(uint128).max, type(uint128).max)
        );
        INonfungiblePositionManager(positionManager).collect(
            INonfungiblePositionManager.CollectParams(tokenId3, address(this), type(uint128).max, type(uint128).max)
        );

        IBobToken(bob).burn(amountBOB1 + amountBOB2 + amountBOB3);

        IBobToken(usdc).approve(bobSwap, amountUSDC1 + amountUSDC2);
        IBobSwap(bobSwap).give(usdc, amountUSDC1 + amountUSDC2);
        IBobToken(usdt).approve(bobSwap, amountUSDT);
        IBobSwap(bobSwap).give(usdt, amountUSDT);

        IBobSwap(bobSwap).setCollateralFees(usdc, 1 ether, 0);
        IBobSwap(bobSwap).setCollateralFees(usdt, 1 ether, 0);
        IBobSwap(bobSwap).setCollateralFees(dai, 1 ether, 0);

        IBobSwap(bobSwap).farm(usdc);
        IBobSwap(bobSwap).farm(usdt);
        IBobSwap(bobSwap).farm(dai);
    }

    function step2() public {
        uint256 bobBalance = IBobToken(bob).balanceOf(address(this));
        IBobSwap(bobSwap).reclaim(address(this), 5_000_000 ether);
        uint256 reclaimed = IBobToken(bob).balanceOf(address(this)) - bobBalance;
        IBobToken(bob).burn(reclaimed);
    }
}
