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

import "./StrategyCurveBase.sol";

contract StrategyCurve3Crv is StrategyCurveBase {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    // Curve stuff
    // Pool to deposit to. In this case it's 3CRV, accepting DAI + USDC + USDT
    address public constant three_pool = 0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7;
    // Pool's Gauge - interactions are mediated through ICurveGauge interface @ this address
    address public constant three_gauge = 0xbFcF63294aD7105dEa65aA58F8AE5BE2D9d0952A;

    // Curve 3Crv token contract address.
    // https://etherscan.io/address/0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490
    // Etherscan states this contract manages 3Crv and USDC
    // The starting deposit is made with this token ^^^
    address public constant three_crv = 0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _neuronTokenAddress,
        address _timelock
    )
        StrategyCurveBase(
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
        IERC20(crv).approve(univ2Router2, type(uint256).max);
    }

    // **** Views ****

    function getMostPremium() public view override returns (address, uint256) {
        uint256[] memory balances = new uint256[](3);
        balances[0] = ICurveFi_3(curve).balances(0); // DAI
        balances[1] = ICurveFi_3(curve).balances(1).mul(10**12); // USDC
        balances[2] = ICurveFi_3(curve).balances(2).mul(10**12); // USDT

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
        return "StrategyCurve3Crv";
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

        // Collects Crv tokens
        // Don't bother voting in v1
        // Creates CRV and transfers to strategy's address (?)
        ICurveMintr(mintr).mint(gauge);
        uint256 _crv = IERC20(crv).balanceOf(address(this));

        if (_crv > 0) {
            _swapToNeurAndDistributePerformanceFees(crv, sushiRouter);
        }

        _crv = IERC20(crv).balanceOf(address(this));

        if (_crv > 0) {
            // x% is sent back to the rewards holder
            // to be used to lock up in as veCRV in a future date
            // Some tokens are accumulated in "treasury" and controller. The % is always subject to discussion.
            uint256 _keepCRV = _crv.mul(keepCRV).div(keepCRVMax);
            if (_keepCRV > 0) {
                IERC20(crv).safeTransfer(
                    IController(controller).treasury(),
                    _keepCRV
                );
            }
            _crv = _crv.sub(_keepCRV);
            // Converts CRV to stablecoins
            _swapUniswap(crv, to, _crv);
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
            ICurveFi_3(curve).add_liquidity(liquidity, 0);
        }

        deposit();
    }
}
