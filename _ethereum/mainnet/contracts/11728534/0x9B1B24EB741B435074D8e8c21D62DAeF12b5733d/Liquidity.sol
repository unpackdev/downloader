/*
    Copyright 2020 Empty Set Squad <emptysetsquad@protonmail.com>

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

pragma solidity ^0.5.17;
pragma experimental ABIEncoderV2;

import "./SafeMath.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./IUniswapV2Pair.sol";
import "./UniswapV2Library.sol";
import "./UniswapV2Router.sol";
import "./Constants.sol";
import "./Permission.sol";
import "./PoolSetters.sol";

contract Liquidity is PoolSetters, Permission {
    using SafeERC20 for IERC20;

    bytes32 private constant FILE = "Liquidity";

    address private constant UNISWAP_FACTORY = address(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);
    IUniswapV2Router02 private constant router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    event Provide(address indexed account, uint256 value, uint256 lessDai, uint256 newUniv2);

    function provide(uint256 value) external onlyFrozen(msg.sender) notPaused validBalance {
        Require.that(totalBonded() > 0, FILE, "insufficient total bonded");

        Require.that(totalRewarded() > 0, FILE, "insufficient total rewarded");

        Require.that(balanceOfRewarded(msg.sender) >= value, FILE, "insufficient rewarded balance");

        (uint256 lessDai, uint256 newUniv2) = addLiquidity(value);

        uint256 totalRewardedWithPhantom = totalRewarded().add(totalPhantom()).add(value);
        uint256 newPhantomFromBonded = totalRewardedWithPhantom.mul(newUniv2).div(totalBonded());

        incrementBalanceOfBonded(msg.sender, newUniv2);
        incrementBalanceOfPhantom(msg.sender, value.add(newPhantomFromBonded));

        emit Provide(msg.sender, value, lessDai, newUniv2);
    }

    function provideOneSided(uint256 value) external onlyFrozen(msg.sender) notPaused validBalance {
        Require.that(totalBonded() > 0, FILE, "insufficient total bonded");
        Require.that(totalRewarded() > 0, FILE, "insufficient total rewarded");
        Require.that(balanceOfRewarded(msg.sender) >= value, FILE, "insufficient rewarded balance");

        uint256 newUniv2 = optimalOneSidedAddLiquidity(value);

        uint256 totalRewardedWithPhantom = totalRewarded().add(totalPhantom()).add(value);
        uint256 newPhantomFromBonded = totalRewardedWithPhantom.mul(newUniv2).div(totalBonded());

        incrementBalanceOfBonded(msg.sender, newUniv2);
        incrementBalanceOfPhantom(msg.sender, value.add(newPhantomFromBonded));

        emit Provide(msg.sender, value, 0, newUniv2);
    }

    // https://github.com/AlphaFinanceLab/alphahomora/blob/734affeb76695c16517fe184d714dfa3033a6484/contracts/5/StrategyAddETHOnly.sol#L40
    function optimalOneSidedAddLiquidity(uint256 dollarAmount) internal returns (uint256) {
        // Optimal one side liquidity supply
        IUniswapV2Pair pair = IUniswapV2Pair(address(stakingToken()));

        address dai = dai();
        address dollar = pair.token0() == dai ? pair.token1() : pair.token0();

        // Compute optimal amount of dollar to be converted to DAI
        (uint256 r0, uint256 r1, ) = pair.getReserves();
        uint256 rIn = pair.token0() == dollar ? r0 : r1;
        uint256 aIn = getOptimalSwapAmount(rIn, dollarAmount);

        // Convert that portion into DAI
        address[] memory path = new address[](2);
        path[0] = dollar;
        path[1] = dai;

        IERC20(dollar).safeApprove(address(router), 0);
        IERC20(dollar).safeApprove(address(router), uint256(-1));
        uint256[] memory outputs = router.swapExactTokensForTokens(aIn, 0, path, address(this), now + 60);

        // Supply liquidity
        uint256 supplyDollarAmount = dollarAmount.sub(aIn);
        uint256 supplyDaiAmount = outputs[1];

        IERC20(dollar).safeApprove(address(router), 0);
        IERC20(dollar).safeApprove(address(router), supplyDollarAmount);

        IERC20(dai).safeApprove(address(router), 0);
        IERC20(dai).safeApprove(address(router), supplyDaiAmount);
        (, , uint256 lpAmountMinted) =
            router.addLiquidity(dollar, dai, supplyDollarAmount, supplyDaiAmount, 0, 0, address(this), now + 60);

        return lpAmountMinted;
    }

    function getOptimalSwapAmount(uint256 amt, uint256 res) internal pure returns (uint256) {
        return sqrt(amt.mul(res.mul(3988000).add(amt.mul(3988009)))).sub(amt.mul(1997)) / 1994;
    }

    function addLiquidity(uint256 dollarAmount) internal returns (uint256, uint256) {
        IUniswapV2Pair pair = IUniswapV2Pair(address(stakingToken()));

        (address tokenA, address tokenB) = (pair.token0(), pair.token1());
        (address dollar, address dai) = (tokenA == dai() ? tokenB : tokenA, dai());
        (uint256 reserveA, uint256 reserveB) = getReserves(dollar, dai);

        uint256 daiAmount =
            (reserveA == 0 && reserveB == 0) ? dollarAmount : UniswapV2Library.quote(dollarAmount, reserveA, reserveB);

        // Assume that the staking token is the pair
        IERC20(dollar).transfer(address(pair), dollarAmount);
        IERC20(dai).transferFrom(msg.sender, address(pair), daiAmount);
        return (daiAmount, pair.mint(address(this)));
    }

    // overridable for testing
    function getReserves(address tokenA, address tokenB) internal view returns (uint256 reserveA, uint256 reserveB) {
        (address token0, ) = UniswapV2Library.sortTokens(tokenA, tokenB);
        (uint256 reserve0, uint256 reserve1, ) =
            IUniswapV2Pair(UniswapV2Library.pairFor(UNISWAP_FACTORY, tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}
