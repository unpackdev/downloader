// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import "./ERC20.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";
import "./StrategyBase.sol";
import "./ISushiMasterchefV2.sol";
import "./ISushiRewarder.sol";

abstract contract StrategySushiEthFarmDoubleRewardBase is StrategyBase {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    // Token addresses
    address public constant sushi = 0x6B3595068778DD592e39A122f4f5a5cF09C90fE2;
    address public immutable rewardToken;

    address public constant sushiMasterChef =
        0xEF0881eC094552b2e128Cf945EF17a6752B4Ec5d;

    uint256 public poolId;

    // How much Reward tokens to keep
    uint256 public keepRewardToken = 500;
    uint256 public keepRewardTokenMax = 10000;

    constructor(
        uint256 _poolId,
        address _lp,
        address _rewardToken,
        address _governance,
        address _strategist,
        address _controller,
        address _neuronTokenAddress,
        address _timelock
    )
        StrategyBase(
            _lp,
            _governance,
            _strategist,
            _controller,
            _neuronTokenAddress,
            _timelock
        )
    {
        poolId = _poolId;
        rewardToken = _rewardToken;
    }

    function setKeepRewardToken(uint256 _keepRewardToken) external {
        require(msg.sender == governance, "!governance");
        keepRewardToken = _keepRewardToken;
    }

    function balanceOfPool() public view override returns (uint256) {
        (uint256 amount, ) = ISushiMasterchefV2(sushiMasterChef).userInfo(
            poolId,
            address(this)
        );
        return amount;
    }

    function getHarvestableSushi() public view returns (uint256) {
        return
            ISushiMasterchefV2(sushiMasterChef).pendingSushi(
                poolId,
                address(this)
            );
    }

    function getHarvestableRewardToken() public view returns (uint256) {
        address rewarder = ISushiMasterchefV2(sushiMasterChef).rewarder(poolId);
        return ISushiRewarder(rewarder).pendingToken(poolId, address(this));
    }

    // **** Setters ****

    function deposit() public override {
        uint256 _want = IERC20(want).balanceOf(address(this));
        if (_want > 0) {
            IERC20(want).safeApprove(sushiMasterChef, 0);
            IERC20(want).safeApprove(sushiMasterChef, _want);
            ISushiMasterchefV2(sushiMasterChef).deposit(
                poolId,
                _want,
                address(this)
            );
        }
    }

    function _withdrawSome(uint256 _amount)
        internal
        override
        returns (uint256)
    {
        ISushiMasterchefV2(sushiMasterChef).withdraw(
            poolId,
            _amount,
            address(this)
        );
        return _amount;
    }

    // **** State Mutations ****

    function harvest() public override onlyBenevolent {
        // Anyone can harvest it at any given time.
        // I understand the possibility of being frontrun
        // But ETH is a dark forest, and I wanna see how this plays out
        // i.e. will be be heavily frontrunned?
        //      if so, a new strategy will be deployed.

        // Collects Sushi and Reward tokens
        ISushiMasterchefV2(sushiMasterChef).harvest(poolId, address(this));

        uint256 _rewardToken = IERC20(rewardToken).balanceOf(address(this));
        uint256 _sushi = IERC20(sushi).balanceOf(address(this));

        if (_rewardToken > 0) {
            _swapToNeurAndDistributePerformanceFees(rewardToken, sushiRouter);
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

        if (_sushi > 0) {
            _swapToNeurAndDistributePerformanceFees(sushi, sushiRouter);
            _sushi = IERC20(sushi).balanceOf(address(this));
        }

        if (_rewardToken > 0) {
            uint256 _amount = _rewardToken.div(2);
            IERC20(rewardToken).safeApprove(sushiRouter, 0);
            IERC20(rewardToken).safeApprove(sushiRouter, _amount);
            _swapSushiswap(rewardToken, weth, _amount);
        }

        if (_sushi > 0) {
            uint256 _amount = _sushi.div(2);
            IERC20(sushi).safeApprove(sushiRouter, 0);
            IERC20(sushi).safeApprove(sushiRouter, _sushi);

            _swapSushiswap(sushi, weth, _amount);
            _swapSushiswap(sushi, rewardToken, _amount);
        }

        // Adds in liquidity for WETH/rewardToken
        uint256 _weth = IERC20(weth).balanceOf(address(this));

        _rewardToken = IERC20(rewardToken).balanceOf(address(this));

        if (_weth > 0 && _rewardToken > 0) {
            IERC20(weth).safeApprove(sushiRouter, 0);
            IERC20(weth).safeApprove(sushiRouter, _weth);

            IERC20(rewardToken).safeApprove(sushiRouter, 0);
            IERC20(rewardToken).safeApprove(sushiRouter, _rewardToken);

            IUniswapRouterV2(sushiRouter).addLiquidity(
                weth,
                rewardToken,
                _weth,
                _rewardToken,
                0,
                0,
                address(this),
                block.timestamp + 60
            );

            // Donates DUST
            IERC20(weth).transfer(
                IController(controller).treasury(),
                IERC20(weth).balanceOf(address(this))
            );
            IERC20(rewardToken).safeTransfer(
                IController(controller).treasury(),
                IERC20(rewardToken).balanceOf(address(this))
            );
        }

        deposit();
    }
}
