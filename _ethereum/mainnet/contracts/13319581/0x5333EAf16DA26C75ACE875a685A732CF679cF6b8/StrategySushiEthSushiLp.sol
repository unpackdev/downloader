// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import "./ERC20.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";
import "./StrategySushiFarmBaseCustomHarvest.sol";

contract StrategySushiEthSushiLp is StrategySushiFarmBaseCustomHarvest {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    // Token/ETH pool id in MasterChef contract
    uint256 public constant sushi_eth_poolId = 12;
    // Token addresses
    address public constant sushi_eth_sushi_lp =
        0x795065dCc9f64b5614C407a6EFDC400DA6221FB0;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _neuronTokenAddress,
        address _timelock
    )
        StrategySushiFarmBaseCustomHarvest(
            sushi,
            sushi_eth_poolId,
            sushi_eth_sushi_lp,
            _governance,
            _strategist,
            _controller,
            _neuronTokenAddress,
            _timelock
        )
    {}

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategySushiEthSushiLp";
    }

    // **** State Mutations ****

    function harvest() public override onlyBenevolent {
        // Anyone can harvest it at any given time.
        // I understand the possibility of being frontrun
        // But ETH is a dark forest, and I wanna see how this plays out
        // i.e. will be be heavily frontrunned?
        //      if so, a new strategy will be deployed.

        // Collects SUSHI tokens
        ISushiChef(masterChef).deposit(poolId, 0);
        uint256 _sushi = IERC20(sushi).balanceOf(address(this));

        if (_sushi > 0) {
            _swapToNeurAndDistributePerformanceFees(sushi, sushiRouter);
        }

        _sushi = IERC20(sushi).balanceOf(address(this));

        if (_sushi > 0) {
            // 10% is locked up for future gov
            uint256 _keepSUSHI = _sushi.mul(keepSUSHI).div(keepSUSHIMax);
            IERC20(sushi).safeTransfer(
                IController(controller).treasury(),
                _keepSUSHI
            );
            uint256 _swap = _sushi.sub(_keepSUSHI);
            IERC20(sushi).safeApprove(sushiRouter, 0);
            IERC20(sushi).safeApprove(sushiRouter, _swap);

            // swap only half of sushi cause since it's used in lp itself
            _swapSushiswap(sushi, weth, _swap.div(2));
        }

        // Swap entire WETH for token1
        uint256 _weth = IERC20(weth).balanceOf(address(this));
        // Adds in liquidity for ETH/sushi
        uint256 _token1 = IERC20(token1).balanceOf(address(this));
        if (_weth > 0 && _token1 > 0) {
            IERC20(token1).safeApprove(sushiRouter, 0);
            IERC20(token1).safeApprove(sushiRouter, _token1);

            IUniswapRouterV2(sushiRouter).addLiquidity(
                weth,
                token1,
                _weth,
                _token1,
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
            IERC20(token1).safeTransfer(
                IController(controller).treasury(),
                IERC20(token1).balanceOf(address(this))
            );
        }

        deposit();
    }
}
