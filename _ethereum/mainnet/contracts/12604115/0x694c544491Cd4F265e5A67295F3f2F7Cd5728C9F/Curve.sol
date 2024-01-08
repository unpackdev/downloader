// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.11;

import "./SafeMath.sol";
import "./IERC20.sol";

/// @notice the stablecoin pool contract
interface IStableSwap {
    function balances(uint256 coin) external view returns (uint256);

    /// @dev the number of coins is hard-coded in curve contracts
    // solhint-disable-next-line
    function add_liquidity(uint256[3] memory amounts, uint256 min_mint_amount)
        external;

    /// @dev the number of coins is hard-coded in curve contracts
    // solhint-disable-next-line
    function remove_liquidity(uint256 _amount, uint256[3] memory min_amounts)
        external;

    // solhint-disable-next-line
    function remove_liquidity_one_coin(
        uint256 tokenAmount,
        int128 tokenIndex,
        uint256 minAmount
    ) external;

    /// @dev For newest curve pools like aave; older pools refer to a private `token` variable.
    // function lp_token() external view returns (address); // solhint-disable-line func-name-mixedcase
}

/// @notice the liquidity gauge, i.e. staking contract, for the stablecoin pool
interface ILiquidityGauge {
    function deposit(uint256 _value) external;

    function deposit(uint256 _value, address _addr) external;

    function withdraw(uint256 _value) external;

    function balanceOf(address account) external view returns (uint256);
}

/**
 * @title Periphery Contract for the Curve 3pool
 * @author APY.Finance
 * @notice This contract enables the APY.Finance system to retrieve the balance
 *         of an underlyer of a Curve LP token. The balance is used as part
 *         of the Chainlink computation of the deployed TVL.  The primary
 *         `getUnderlyerBalance` function is invoked indirectly when a
 *         Chainlink node calls `balanceOf` on the APYAssetAllocationRegistry.
 */
contract CurvePeriphery {
    using SafeMath for uint256;

    /**
     * @notice Returns the balance of an underlying token represented by
     *         an account's LP token balance.
     * @param stableSwap the liquidity pool comprised of multiple underlyers
     * @param gauge the staking contract for the LP tokens
     * @param lpToken the LP token representing the share of the pool
     * @param coin the index indicating which underlyer
     * @return balance
     */
    function getUnderlyerBalance(
        address account,
        IStableSwap stableSwap,
        ILiquidityGauge gauge,
        IERC20 lpToken,
        uint256 coin
    ) external view returns (uint256 balance) {
        require(address(stableSwap) != address(0), "INVALID_STABLESWAP");
        require(address(gauge) != address(0), "INVALID_GAUGE");
        require(address(lpToken) != address(0), "INVALID_LP_TOKEN");

        uint256 poolBalance = getPoolBalance(stableSwap, coin);
        (uint256 lpTokenBalance, uint256 lpTokenSupply) =
            getLpTokenShare(account, stableSwap, gauge, lpToken);

        balance = lpTokenBalance.mul(poolBalance).div(lpTokenSupply);
    }

    function getPoolBalance(IStableSwap stableSwap, uint256 coin)
        public
        view
        returns (uint256)
    {
        require(address(stableSwap) != address(0), "INVALID_STABLESWAP");
        return stableSwap.balances(coin);
    }

    function getLpTokenShare(
        address account,
        IStableSwap stableSwap,
        ILiquidityGauge gauge,
        IERC20 lpToken
    ) public view returns (uint256 balance, uint256 totalSupply) {
        require(address(stableSwap) != address(0), "INVALID_STABLESWAP");
        require(address(gauge) != address(0), "INVALID_GAUGE");
        require(address(lpToken) != address(0), "INVALID_LP_TOKEN");

        totalSupply = lpToken.totalSupply();
        balance = lpToken.balanceOf(account);
        balance = balance.add(gauge.balanceOf(account));
    }
}
