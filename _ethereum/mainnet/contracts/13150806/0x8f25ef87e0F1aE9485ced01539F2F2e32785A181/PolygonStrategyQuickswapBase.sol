// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import "./ERC20.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";
import "./PolygonStrategyBase.sol";
import "./IPolygonSushiMiniChef.sol";
import "./IPolygonSushiRewarder.sol";
import "./PolygonStrategyStakingRewardsBase.sol";

abstract contract PolygonStrategyQuickswapBase is
    PolygonStrategyStakingRewardsBase
{
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    // Token addresses
    address public constant quick = 0x831753DD7087CaC61aB5644b308642cc1c33Dc13;
    address public constant rewardToken = quick;


    address public token0;
    address public token1;

    // How much Reward tokens to keep
    uint256 public keepRewardToken = 0;
    uint256 public keepRewardTokenMax = 10000;

    constructor(
        address _token0,
        address _token1,
        address _staking_rewards,
        address _lp_token,
        address _governance,
        address _strategist,
        address _controller,
        address _neuronTokenAddress,
        address _timelock
    )
        PolygonStrategyStakingRewardsBase(
            _staking_rewards,
            _lp_token,
            _governance,
            _strategist,
            _controller,
            _neuronTokenAddress,
            _timelock
        )
    {
        token0 = _token0;
        token1 = _token1;

        IERC20(token0).approve(quickswapRouter, type(uint256).max);
        IERC20(token1).approve(quickswapRouter, type(uint256).max);
    }

    function setKeepRewardToken(uint256 _keepRewardToken) external {
        require(msg.sender == governance, "!governance");
        keepRewardToken = _keepRewardToken;
    }

    // **** State Mutations ****

    function harvest() public override onlyBenevolent {
        // Collects Quick tokens
        IStakingRewards(rewards).getReward();

        uint256 _rewardToken = IERC20(rewardToken).balanceOf(address(this));

        if (_rewardToken > 0 && performanceTreasuryFee > 0) {
            _swapToNeurAndDistributePerformanceFees(rewardToken, quickswapRouter);
            uint256 _keepRewardToken = _rewardToken.mul(keepRewardToken).div(
                keepRewardTokenMax
            );
            if (_keepRewardToken > 0) {
                IERC20(rewardToken).safeTransfer(
                    IController(controller).treasury(),
                    _keepRewardToken
                );
            }
            _rewardToken = IERC20(rewardToken).balanceOf(address(this));
        }

        if (_rewardToken > 0) {
            IERC20(rewardToken).safeApprove(sushiRouter, 0);
            IERC20(rewardToken).safeApprove(sushiRouter, _rewardToken);
            _swapQuickswap(rewardToken, weth, _rewardToken);
        }

        // Swap half WETH for token0
        uint256 _weth = IERC20(weth).balanceOf(address(this));
        if (_weth > 0 && token0 != weth) {
            _swapQuickswap(weth, token0, _weth.div(2));
        }

        // Swap half WETH for token1
        if (_weth > 0 && token1 != weth) {
            _swapQuickswap(weth, token1, _weth.div(2));
        }

        uint256 _token0 = IERC20(token0).balanceOf(address(this));
        uint256 _token1 = IERC20(token1).balanceOf(address(this));
        if (_token0 > 0 && _token1 > 0) {
            IERC20(token0).safeApprove(quickswapRouter, 0);
            IERC20(token0).safeApprove(quickswapRouter, _token0);
            IERC20(token1).safeApprove(quickswapRouter, 0);
            IERC20(token1).safeApprove(quickswapRouter, _token1);

            IUniswapRouterV2(quickswapRouter).addLiquidity(
                token0,
                token1,
                _token0,
                _token1,
                0,
                0,
                address(this),
                block.timestamp + 60
            );

            // Donates DUST
            IERC20(token0).transfer(
                IController(controller).treasury(),
                IERC20(token0).balanceOf(address(this))
            );
            IERC20(token1).safeTransfer(
                IController(controller).treasury(),
                IERC20(token1).balanceOf(address(this))
            );
        }

        deposit();
    }
}
