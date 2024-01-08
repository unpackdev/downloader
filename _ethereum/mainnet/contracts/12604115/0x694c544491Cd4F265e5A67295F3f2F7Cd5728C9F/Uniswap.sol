// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.11;

import "./SafeMath.sol";
import "./IERC20.sol";

/// @notice Uniswap contract for adding/removing liquidity from pools
interface IUniswapV2Router {
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);
}

interface IUniswapV2Pair is IERC20 {
    function token0() external view returns (address);

    function token1() external view returns (address);
}

/**
 * @title Periphery Contract for the Uniswap V2 Router
 * @author APY.Finance
 * @notice This contract enables the APY.Finance system to retrieve the balance
 *         of an underlyer of a Uniswap LP token. The balance is used as part
 *         of the Chainlink computation of the deployed TVL.  The primary
 *         `getUnderlyerBalance` function is invoked indirectly when a
 *         Chainlink node calls `balanceOf` on the APYAssetAllocationRegistry.
 */
contract UniswapPeriphery {
    using SafeMath for uint256;

    /**
     * @notice Returns the balance of an underlying token represented by
     *         an account's LP token balance.
     * @param lpToken the LP token representing the share of the pool
     * @param tokenIndex the index indicating which underlyer
     * @return balance
     */
    function getUnderlyerBalance(
        address account,
        IUniswapV2Pair lpToken,
        uint256 tokenIndex
    ) external view returns (uint256 balance) {
        require(address(lpToken) != address(0), "INVALID_LP_TOKEN");

        uint256 poolBalance = getPoolBalance(lpToken, tokenIndex);
        (uint256 lpTokenBalance, uint256 lpTokenSupply) =
            getLpTokenShare(account, lpToken);

        balance = lpTokenBalance.mul(poolBalance).div(lpTokenSupply);
    }

    function getPoolBalance(IUniswapV2Pair lpToken, uint256 tokenIndex)
        public
        view
        returns (uint256 poolBalance)
    {
        require(address(lpToken) != address(0), "INVALID_LP_TOKEN");
        IERC20 token;
        if (tokenIndex == 0) {
            token = IERC20(lpToken.token0());
        } else if (tokenIndex == 1) {
            token = IERC20(lpToken.token1());
        } else {
            revert("INVALID_TOKEN_INDEX");
        }
        poolBalance = token.balanceOf(address(lpToken));
    }

    function getLpTokenShare(address account, IERC20 lpToken)
        public
        view
        returns (uint256 balance, uint256 totalSupply)
    {
        require(address(lpToken) != address(0), "INVALID_LP_TOKEN");

        totalSupply = lpToken.totalSupply();
        balance = lpToken.balanceOf(account);
    }
}
