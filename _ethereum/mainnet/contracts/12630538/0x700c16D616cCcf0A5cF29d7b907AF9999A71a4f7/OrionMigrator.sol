// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.7.6;

import "./IUniswapV2Pair.sol";
import "./IUniswapV2Factory.sol";
import "./IStakingRewards.sol";
import "./IOrionPoolV2Router01.sol";
import "./IOrionMigrator.sol";
import "./IWETH9.sol";

import "./IERC20.sol";
import "./SafeERC20.sol";

contract OrionMigrator is IOrionMigrator {
    using SafeERC20 for IERC20;

    IStakingRewards public immutable stakingRewards;
    IUniswapV2Pair public immutable uniswapPair;
    IERC20 public immutable token0;
    IERC20 public immutable token1;
    IOrionPoolV2Router01 public immutable router;
    IWETH9 public immutable WETH9;

    constructor(address _pair, address _router, address _WETH9, address _stakingRewards) {
        uniswapPair = IUniswapV2Pair(_pair);
        token0 = IERC20(IUniswapV2Pair(_pair).token0());
        token1 = IERC20(IUniswapV2Pair(_pair).token1());
        router = IOrionPoolV2Router01(_router);
        WETH9 = IWETH9(_WETH9);
        stakingRewards = IStakingRewards(_stakingRewards);
    }

    receive() external payable {
        require(msg.sender == address(WETH9));
    }

    function migrate(uint256 tokensToMigrate, uint amount0Min, uint amount1Min, address to, uint deadline) external override {
        require(uniswapPair.transferFrom(msg.sender, address(uniswapPair), tokensToMigrate), 'TRANSFER_FROM_FAILED');

        (uint256 amount0V1, uint256 amount1V1) = uniswapPair.burn(address(this));

        token0.safeApprove(address(router), amount0V1);
        token1.safeApprove(address(router), amount1V1);

        (uint amount0V2, uint amount1V2, uint liquidity) = router.addLiquidity(address(token0), address(token1),
            amount0V1,
            amount1V1,
            amount0Min,
            amount1Min,
            address(this),
            deadline
        );

        address ornPair = IUniswapV2Factory(router.factory()).getPair(address(token0), address(token1));

        IERC20(ornPair).safeApprove(address(stakingRewards), liquidity);
        stakingRewards.stakeTo(liquidity, to);

        emit TestCalc(amount0V1, amount1V1, amount0V2, amount1V2);
        if (amount0V2 < amount0V1) {
            token0.safeApprove(address(router), 0);

            uint256 refund0 = amount0V1 - amount0V2;
            if (address(token0) == address(WETH9)) {
                WETH9.withdraw(refund0);
                msg.sender.transfer(refund0);
            } else {
                token0.safeTransfer(msg.sender, refund0);
            }
        }

        if (amount1V2 < amount1V1) {
            token1.safeApprove(address(router), 0);

            uint256 refund1 = amount1V1 - amount1V2;
            if (address(token1) == address(WETH9)) {
                WETH9.withdraw(refund1);
                msg.sender.transfer(refund1);
            } else {
                token1.safeTransfer(msg.sender, refund1);
            }
        }
    }

    event TestCalc
    (
        uint256 amount0V1,
        uint256 amount1V1,
        uint256 amount0V2,
        uint256 amount1V2
    );
}
