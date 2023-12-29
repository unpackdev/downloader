// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;
pragma abicoder v2;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./IBalancerCore.sol";

/**
 * @title   BalInvestor
 * @notice  Deposits LIT or WETH into a LIT/WETH BPT. Hooks into TWAP to determine minOut.
 * @dev     Abstract contract for depositing LIT -> balBPT -> auraBAL via crvDepositor
 */
abstract contract BalInvestor {
    using SafeERC20 for IERC20;

    IBalancerVault public immutable BALANCER_VAULT;
    address public immutable LIT;
    address public immutable WETH;
    address public immutable BALANCER_POOL_TOKEN;
    bytes32 public immutable BAL_ETH_POOL_ID;

    constructor(
        IBalancerVault _balancerVault,
        address _lit,
        address _weth,
        bytes32 _balETHPoolId
    ) {
        (
            address poolAddress, /* */

        ) = _balancerVault.getPool(_balETHPoolId);
        require(poolAddress != address(0), "!poolAddress");

        BALANCER_VAULT = _balancerVault;
        LIT = _lit;
        WETH = _weth;
        BALANCER_POOL_TOKEN = poolAddress;
        BAL_ETH_POOL_ID = _balETHPoolId;
    }

    function _setApprovals() internal {
        IERC20(WETH).safeApprove(address(BALANCER_VAULT), type(uint256).max);
        IERC20(LIT).safeApprove(address(BALANCER_VAULT), type(uint256).max);
    }

    function _getBptPrice() internal view returns (uint256) {
        IPriceOracle.OracleAverageQuery[] memory queries = new IPriceOracle.OracleAverageQuery[](1);

        queries[0].variable = IPriceOracle.Variable.BPT_PRICE;
        queries[0].secs = 3600; // last hour
        queries[0].ago = 0; // now

        // Gets the balancer time weighted average price denominated in LIT
        return IPriceOracle(BALANCER_POOL_TOKEN).getTimeWeightedAverage(queries)[0];
    }

    function _getPairPrice() internal view returns (uint256) {
        IPriceOracle.OracleAverageQuery[] memory queries = new IPriceOracle.OracleAverageQuery[](1);

        queries[0].variable = IPriceOracle.Variable.PAIR_PRICE;
        queries[0].secs = 3600; // last hour
        queries[0].ago = 0; // now

        // Gets the balancer time weighted average price for LIT in ETH
        // e.g LIT price is 0.10$ and ETH price is 1800$ -> return 0.56e14
        return IPriceOracle(BALANCER_POOL_TOKEN).getTimeWeightedAverage(queries)[0];
    }

    function _getMinOut(
        uint256 amount,
        uint256 minOutBps,
        uint256 asset
    ) internal view returns (uint256) {
        require(asset == 0 || asset == 1, "!asset");

        // Gets the balancer time weighted average price denominated in WETH
        // e.g.  if 1 WETH == 0.4 BPT, bptOraclePrice == 2.5
        uint256 bptOraclePrice = _getBptPrice(); // e.g bptOraclePrice = 3.52e14

        if (asset == 1) {
            // get min out for LIT in
            uint256 pairOraclePrice = _getPairPrice(); // e.g pairOraclePrice = 0.56e14
            bptOraclePrice = (bptOraclePrice * 1e18) / pairOraclePrice; // e.g bptOraclePriceInLit = 6.28e18
        }

        // e.g. minOut = (((100e18 * 1e18) / 2.5e18) * 9980) / 10000;
        // e.g. minout = 39.92e18
        uint256 minOut = (((amount * 1e18) / bptOraclePrice) * minOutBps) / 10000;
        return minOut;
    }

    // invest either WETH or LIT in BAL-20WETH-80LIT pool
    function _investSingleToPool(
        uint256 amount,
        uint256 minOut,
        uint256 asset
    ) internal {
        IAsset[] memory assets = new IAsset[](2);
        assets[0] = IAsset(WETH);
        assets[1] = IAsset(LIT);
        uint256[] memory maxAmountsIn = new uint256[](2);

        // asset == 0: invest WETH, asset == 1: invest LIT
        if (asset == 0) {
            maxAmountsIn[0] = amount;
            maxAmountsIn[1] = 0;
        } else {
            maxAmountsIn[0] = 0;
            maxAmountsIn[1] = amount;
        }

        BALANCER_VAULT.joinPool(
            BAL_ETH_POOL_ID,
            address(this),
            address(this),
            IBalancerVault.JoinPoolRequest(
                assets,
                maxAmountsIn,
                abi.encode(IBalancerVault.JoinKind.EXACT_TOKENS_IN_FOR_BPT_OUT, maxAmountsIn, minOut),
                false // Don't use internal balances
            )
        );
    }
}
