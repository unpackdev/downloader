// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./INonfungiblePlanManager.sol";
import "./INonfungibleTokenPlanDescriptor.sol";
import "./IERC20Metadata.sol";
import "./PoolAddress.sol";
import "./NFTDescriptor.sol";
import "./SafeERC20Namer.sol";

contract NonfungibleTokenPlanDescriptor is INonfungibleTokenPlanDescriptor {
    address public immutable WETH9;

    constructor(address _WETH9) {
        WETH9 = _WETH9;
    }

    function tokenURI(INonfungiblePlanManager planManager, uint256 tokenId)
        external
        view
        override
        returns (string memory)
    {
        (
            INonfungiblePlanManager.Plan memory plan,
            INonfungiblePlanManager.PlanStatistics memory statistics
        ) = planManager.getPlan(tokenId);

        address pool = PoolAddress.computeAddress(
            planManager.factory(),
            PoolAddress.getPoolInfo(plan.token0, plan.token1, plan.frequency)
        );

        address tokenAddress = plan.token1;
        address stableCoinAddress = plan.token0;
        return
            NFTDescriptor.constructTokenURI(
                NFTDescriptor.ConstructTokenURIParams({
                    tokenId: tokenId,
                    stableCoinAddress: stableCoinAddress,
                    stableCoinSymbol: SafeERC20Namer.tokenSymbol(
                        stableCoinAddress
                    ),
                    tokenAddress: tokenAddress,
                    tokenSymbol: tokenAddress == WETH9
                        ? "ETH"
                        : SafeERC20Namer.tokenSymbol(tokenAddress),
                    tokenDecimals: IERC20Metadata(tokenAddress).decimals(),
                    frequency: plan.frequency,
                    poolAddress: pool,
                    tickAmount: plan.tickAmount,
                    ongoing: plan.tickAmount * statistics.remainingTicks,
                    invested: statistics.swapAmount1,
                    withdrawn: statistics.withdrawnAmount1,
                    ticks: statistics.ticks,
                    remainingTicks: statistics.remainingTicks
                })
            );
    }
}
