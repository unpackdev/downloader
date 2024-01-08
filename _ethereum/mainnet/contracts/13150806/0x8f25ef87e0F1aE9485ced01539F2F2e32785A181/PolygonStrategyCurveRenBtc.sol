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

contract PolygonStrategyCurveRenBtc is PolygonStrategyCurveBase {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    // Curve stuff
    // Pool to deposit to. In this case it's renBTC, accepting wBTC + renBTC
    // https://polygon.curve.fi/ren
    address public constant curve_renBTC_pool =
        0xC2d95EEF97Ec6C17551d45e77B590dc1F9117C67;
    // Pool's Gauge - interactions are mediated through ICurveGauge interface @ this address
    address public constant curve_renBTC_gauge =
        0xffbACcE0CC7C19d46132f1258FC16CF6871D153c;
    // Curve.fi amWBTC/renBTC (btcCRV) token contract address.
    // The starting deposit is made with this token ^^^
    address public constant curve_renBTC_lp = 0xf8a57c1d3b9629b77b6726a042ca48990A84Fb49;
    address public constant wbtc = 0x1BFD67037B42Cf73acF2047067bd4F2C47D9BfD6;
    address public constant renBTC = 0xDBf31dF14B66535aF65AaC99C32e9eA844e14501;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _neuronTokenAddress,
        address _timelock
    )
        PolygonStrategyCurveBase(
            curve_renBTC_pool,
            curve_renBTC_gauge,
            curve_renBTC_lp,
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

    function getName() external pure override returns (string memory) {
        return "PolygonStrategyCurveRenBtc";
    }

    function getMostPremium() pure public override returns (address, uint256) {
        // Always return wbtc because there is no liquidity for renBTC tokens
        return (wbtc, 0);
    }

    // **** State Mutations ****
    // Function to harvest pool rewards, convert to stablecoins and reinvest to pool
    function harvest() public override onlyBenevolent {
        // Anyone can harvest it at any given time.
        // I understand the possibility of being frontrun
        // But ETH is a dark forest, and I wanna see how this plays out
        // i.e. will be be heavily frontrunned?
        //      if so, a new strategy will be deployed.

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
