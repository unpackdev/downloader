// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import "./StrategyStakingRewardsBase.sol";

abstract contract StrategyFeiFarmBase is StrategyStakingRewardsBase {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    // Token addresses
    address public constant fei = 0x956F47F50A910163D8BF957Cf5846D573E7f87CA;
    address public constant tribe = 0xc7283b66Eb1EB5FB86327f08e1B5816b0720212B;

    // How much TRIBE tokens to keep?
    uint256 public keepTRIBE = 0;
    uint256 public constant keepTRIBEMax = 10000;

    // Uniswap swap paths
    address[] public tribe_fei_path;

    constructor(
        address _rewards,
        address _lp,
        address _governance,
        address _strategist,
        address _controller,
        address _neuronTokenAddress,
        address _timelock
    )
        StrategyStakingRewardsBase(
            _rewards,
            _lp,
            _governance,
            _strategist,
            _controller,
            _neuronTokenAddress,
            _timelock
        )
    {
        tribe_fei_path = new address[](2);
        tribe_fei_path[0] = tribe;
        tribe_fei_path[1] = fei;

        IERC20(fei).approve(univ2Router2, type(uint256).max);
        IERC20(tribe).approve(univ2Router2, type(uint256).max);
    }

    // **** Setters ****

    function setKeepTRIBE(uint256 _keepTRIBE) external {
        require(msg.sender == timelock, "!timelock");
        keepTRIBE = _keepTRIBE;
    }

    // **** State Mutations ****

    function harvest() public override onlyBenevolent {
        // Anyone can harvest it at any given time.
        // I understand the possibility of being frontrun
        // But ETH is a dark forest, and I wanna see how this plays out
        // i.e. will be be heavily frontrunned?
        //      if so, a new strategy will be deployed.

        // Collects TRIBE tokens
        IStakingRewards(rewards).getReward();
        uint256 _tribe = IERC20(tribe).balanceOf(address(this));
        uint256 _fei = IERC20(fei).balanceOf(address(this));

        if (_tribe > 0 && performanceTreasuryFee > 0) {
            uint256 tribePerfomanceFeeAmount = _tribe
                .mul(performanceTreasuryFee)
                .div(performanceTreasuryMax);
            _swapUniswapWithPath(tribe_fei_path, tribePerfomanceFeeAmount);
            _fei = IERC20(fei).balanceOf(address(this));
            _swapAmountToNeurAndDistributePerformanceFees(
                fei,
                _fei,
                sushiRouter
            );
        }

        _tribe = IERC20(tribe).balanceOf(address(this));

        if (_tribe > 0 && performanceTreasuryFee > 0) {
            // 10% is locked up for future gov
            uint256 _keepTRIBE = _tribe.mul(keepTRIBE).div(keepTRIBEMax);
            IERC20(tribe).safeTransfer(
                IController(controller).treasury(),
                _keepTRIBE
            );
            _tribe = _tribe.sub(_keepTRIBE);

            _swapUniswapWithPath(tribe_fei_path, _tribe.div(2));
        }

        // Adds in liquidity for FEI/TRIBE
        _fei = IERC20(fei).balanceOf(address(this));
        _tribe = IERC20(tribe).balanceOf(address(this));
        if (_fei > 0 && _tribe > 0) {
            IUniswapRouterV2(univ2Router2).addLiquidity(
                fei,
                tribe,
                _fei,
                _tribe,
                0,
                0,
                address(this),
                block.timestamp + 60
            );

            // Donates DUST
            IERC20(fei).safeTransfer(
                IController(controller).treasury(),
                IERC20(fei).balanceOf(address(this))
            );
            IERC20(tribe).safeTransfer(
                IController(controller).treasury(),
                IERC20(tribe).balanceOf(address(this))
            );
        }

        // We want to get back FEI-TRIBE LP tokens
        deposit();
    }
}
