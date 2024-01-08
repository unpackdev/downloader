// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import "./ERC20.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";
import "./PolygonStrategySushiDoubleRewardBase.sol";

contract PolygonStrategySushiDoubleDaiPickleLp is PolygonStrategyBase {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    // Token addresses
    address public constant sushi = 0x0b3F868E0BE5597D5DB7fEB59E1CADBb0fdDa50a;
    address public constant rewardToken = wmatic;

    address public constant sushiMiniChef =
        0x0769fd68dFb93167989C6f7254cd0D766Fb2841F;

    // How much Reward tokens to keep
    uint256 public keepRewardToken = 500;
    uint256 public keepRewardTokenMax = 10000;

    address public constant sushi_dai_pickle_lp =
        0x57602582eB5e82a197baE4E8b6B80E39abFC94EB;
    uint256 public constant sushi_dai_pickle_poolId = 37;
    // Token0
    address public constant pickle_token =
        0x2b88aD57897A8b496595925F43048301C37615Da;
    // Token1
    address public constant dai = 0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063;
    address public constant token0 = pickle_token;
    address public constant token1 = dai;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _neuronTokenAddress,
        address _timelock
    )
        PolygonStrategyBase(
            sushi_dai_pickle_lp,
            _governance,
            _strategist,
            _controller,
            _neuronTokenAddress,
            _timelock
        )
    {}

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "PolygonStrategySushiDoubleDaiPickleLp";
    }

    function setKeepRewardToken(uint256 _keepRewardToken) external {
        require(msg.sender == governance, "!governance");
        keepRewardToken = _keepRewardToken;
    }

    function balanceOfPool() public view override returns (uint256) {
        (uint256 amount, ) = IPolygonSushiMiniChef(sushiMiniChef).userInfo(
            sushi_dai_pickle_poolId,
            address(this)
        );
        return amount;
    }

    function getHarvestable() external view returns (uint256, uint256) {
        uint256 _pendingSushi = IPolygonSushiMiniChef(sushiMiniChef)
            .pendingSushi(sushi_dai_pickle_poolId, address(this));
        IPolygonSushiRewarder rewarder = IPolygonSushiRewarder(
            IPolygonSushiMiniChef(sushiMiniChef).rewarder(
                sushi_dai_pickle_poolId
            )
        );
        (, uint256[] memory _rewardAmounts) = rewarder.pendingTokens(
            sushi_dai_pickle_poolId,
            address(this),
            0
        );

        uint256 _pendingRewardToken;
        if (_rewardAmounts.length > 0) {
            _pendingRewardToken = _rewardAmounts[0];
        }
        return (_pendingSushi, _pendingRewardToken);
    }

    // **** Setters ****

    function deposit() public override {
        uint256 _want = IERC20(want).balanceOf(address(this));
        if (_want > 0) {
            IERC20(want).safeApprove(sushiMiniChef, 0);
            IERC20(want).safeApprove(sushiMiniChef, _want);
            IPolygonSushiMiniChef(sushiMiniChef).deposit(
                sushi_dai_pickle_poolId,
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
        IPolygonSushiMiniChef(sushiMiniChef).withdraw(
            sushi_dai_pickle_poolId,
            _amount,
            address(this)
        );
        return _amount;
    }

    function harvest() public override onlyBenevolent {
        // Anyone can harvest it at any given time.
        // I understand the possibility of being frontrun
        // But ETH is a dark forest, and I wanna see how this plays out
        // i.e. will be be heavily frontrunned?
        //      if so, a new strategy will be deployed.

        // Collects Sushi and Reward tokens
        IPolygonSushiMiniChef(sushiMiniChef).harvest(
            sushi_dai_pickle_poolId,
            address(this)
        );

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
            IERC20(rewardToken).safeApprove(sushiRouter, 0);
            IERC20(rewardToken).safeApprove(sushiRouter, _rewardToken);
            _swapSushiswap(rewardToken, weth, _rewardToken);
        }

        if (_sushi > 0) {
            IERC20(sushi).safeApprove(sushiRouter, 0);
            IERC20(sushi).safeApprove(sushiRouter, _sushi);

            _swapSushiswap(sushi, weth, _sushi);
        }

        // Swap all WETH for DAI first
        uint256 _weth = IERC20(weth).balanceOf(address(this));

        if (_weth > 0) {
            _swapSushiswap(weth, dai, _weth);
        }

        uint256 _dai = IERC20(dai).balanceOf(address(this));
        // Swap half DAI for pickle
        if (_dai > 0) {
            IERC20(dai).safeApprove(sushiRouter, 0);
            IERC20(dai).safeApprove(sushiRouter, _dai.div(2));
            _swapSushiswap(dai, pickle_token, _dai.div(2));
        }

        uint256 _token0 = IERC20(token0).balanceOf(address(this));
        uint256 _token1 = IERC20(token1).balanceOf(address(this));
        if (_token0 > 0 && _token1 > 0) {
            IERC20(token0).safeApprove(sushiRouter, 0);
            IERC20(token0).safeApprove(sushiRouter, _token0);
            IERC20(token1).safeApprove(sushiRouter, 0);
            IERC20(token1).safeApprove(sushiRouter, _token1);

            IUniswapRouterV2(sushiRouter).addLiquidity(
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
