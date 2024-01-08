// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import "./ERC20.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";
import "./Address.sol";

import "./PolygonStrategyBase.sol";
import "./ICurve.sol";

// Base contract for Curve based staking contract interfaces

abstract contract PolygonStrategyCurveBase is PolygonStrategyBase {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    // Curve DAO
    // Pool's gauge => all the interactions are held through this address, ICurveGauge interface
    address public immutable gauge;
    // Curve's contract address => depositing here
    address public immutable curve;

    // stablecoins
    address public constant dai = 0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063;
    address public constant usdc = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;
    address public constant usdt = 0xc2132D05D31c914a87C6611C10748AEb04B58e8F;

    // rewards
    address public constant crv = 0x172370d5Cd63279eFa6d502DAB29171933a610AF;

    // How much CRV tokens to keep
    uint256 public keepCRV = 500;
    uint256 public keepCRVMax = 10000;

    constructor(
        address _curve,
        address _gauge,
        address _want,
        address _governance,
        address _strategist,
        address _controller,
        address _neuronTokenAddress,
        address _timelock
    )
        PolygonStrategyBase(
            _want,
            _governance,
            _strategist,
            _controller,
            _neuronTokenAddress,
            _timelock
        )
    {
        curve = _curve;
        gauge = _gauge;
    }

    // **** Getters ****

    function balanceOfPool() public view override returns (uint256) {
        return ICurveGauge(gauge).balanceOf(address(this));
    }

    function getHarvestable() external returns (uint256) {
        return ICurveGauge(gauge).claimable_tokens(address(this));
    }

    function getMostPremium() public view virtual returns (address, uint256);

    // **** Setters ****

    function setKeepCRV(uint256 _keepCRV) external {
        require(msg.sender == governance, "!governance");
        keepCRV = _keepCRV;
    }

    // **** State Mutation functions ****

    function deposit() public override {
        // Checking our contract's wanted/accepted token balance
        uint256 _want = IERC20(want).balanceOf(address(this));
        if (_want > 0) {
            IERC20(want).safeApprove(gauge, 0);
            IERC20(want).safeApprove(gauge, _want);
            ICurveGauge(gauge).deposit(_want);
        }
    }

    function _withdrawSome(uint256 _amount)
        internal
        override
        returns (uint256)
    {
        ICurveGauge(gauge).withdraw(_amount);
        return _amount;
    }
}
