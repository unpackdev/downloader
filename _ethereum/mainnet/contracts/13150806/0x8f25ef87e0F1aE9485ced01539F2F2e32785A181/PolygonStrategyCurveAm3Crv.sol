// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import "./ERC20.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";
import "./Address.sol";

import "./INeuronPool.sol";
import "./ICurve.sol";
import "./IUniswapRouterV2.sol";
import "./IController.sol";

import "./PolygonStrategyCurveBase.sol";

contract PolygonStrategyCurveAm3Crv is PolygonStrategyCurveBase {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    // Curve stuff
    // Pool to deposit to. In this case it's 3CRV, accepting DAI + USDC + USDT
    address public three_pool = 0x445FE580eF8d70FF569aB36e80c647af338db351;
    // Pool's Gauge - interactions are mediated through ICurveGauge interface @ this address
    address public three_gauge = 0x19793B454D3AfC7b454F206Ffe95aDE26cA6912c;
    // Curve 3Crv token contract address.
    // https://etherscan.io/address/0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490
    // Etherscan states this contract manages 3Crv and USDC
    // The starting deposit is made with this token ^^^
    address public three_crv = 0xE7a24EF0C5e95Ffb0f6684b813A78F2a3AD7D171;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _neuronTokenAddress,
        address _timelock
    )
        PolygonStrategyCurveBase(
            three_pool,
            three_gauge,
            three_crv,
            _governance,
            _strategist,
            _controller,
            _neuronTokenAddress,
            _timelock
        )
    {
        IERC20(crv).approve(quickswapRouter, type(uint256).max);
    }

    // **** Views ****

    function getMostPremium() public view override returns (address, uint256) {
        uint256[] memory balances = new uint256[](3);
        balances[0] = ICurveFi_Polygon_3(curve).balances(0); // DAI
        balances[1] = ICurveFi_Polygon_3(curve).balances(1).mul(10**12); // USDC
        balances[2] = ICurveFi_Polygon_3(curve).balances(2).mul(10**12); // USDT

        // DAI
        if (balances[0] < balances[1] && balances[0] < balances[2]) {
            return (dai, 0);
        }

        // USDC
        if (balances[1] < balances[0] && balances[1] < balances[2]) {
            return (usdc, 1);
        }

        // USDT
        if (balances[2] < balances[0] && balances[2] < balances[1]) {
            return (usdt, 2);
        }

        // If they're somehow equal, we just want DAI
        return (dai, 0);
    }

    function getName() external pure override returns (string memory) {
        return "PolygonStrategyCurveAm3Crv";
    }

    // **** State Mutations ****
    // Function to harvest pool rewards, convert to stablecoins and reinvest to pool
    function harvest() public override onlyBenevolent {
        // Anyone can harvest it at any given time.
        // I understand the possibility of being frontrun
        // But ETH is a dark forest, and I wanna see how this plays out
        // i.e. will be be heavily frontrunned?
        // if so, a new strategy will be deployed.

        // stablecoin we want to convert to
        (address to, uint256 toIndex) = getMostPremium();

        ICurveGauge(gauge).claim_rewards(address(this));

        uint256 _crv = IERC20(crv).balanceOf(address(this));

        if (_crv > 0) {
            _swapToNeurAndDistributePerformanceFees(crv, quickswapRouter);
        }

        uint256 _wmatic = IERC20(wmatic).balanceOf(address(this));

        if (_wmatic > 0) {
            _swapToNeurAndDistributePerformanceFees(wmatic, quickswapRouter);
        }

        _crv = IERC20(crv).balanceOf(address(this));

        if (_crv > 0) {
            IERC20(crv).safeApprove(quickswapRouter, 0);
            IERC20(crv).safeApprove(quickswapRouter, _crv);
            _swapQuickswap(crv, to, _crv);
        }

        _wmatic = IERC20(wmatic).balanceOf(address(this));
        if (_wmatic > 0) {
            IERC20(wmatic).safeApprove(quickswapRouter, 0);
            IERC20(wmatic).safeApprove(quickswapRouter, _wmatic);
            _swapQuickswap(wmatic, to, _wmatic);
        }

        // Adds liquidity to curve.fi's pool
        // to get back want (scrv)
        uint256 _to = IERC20(to).balanceOf(address(this));
        if (_to > 0) {
            IERC20(to).safeApprove(curve, 0);
            IERC20(to).safeApprove(curve, _to);
            uint256[3] memory liquidity;
            liquidity[toIndex] = _to;
            // Transferring stablecoins back to Curve
            ICurveFi_Polygon_3(curve).add_liquidity(liquidity, 0, true);
        }

        deposit();
    }
}
