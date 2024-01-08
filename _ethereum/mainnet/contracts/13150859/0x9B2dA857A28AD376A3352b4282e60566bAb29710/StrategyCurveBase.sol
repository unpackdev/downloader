// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import "./ERC20.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";
import "./Address.sol";

import "./StrategyBase.sol";
import "./ICurve.sol";

// Base contract for Curve based staking contract interfaces

abstract contract StrategyCurveBase is StrategyBase {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    // Curve DAO
    // Pool's gauge => all the interactions are held through this address, ICurveGauge interface
    address public gauge;
    // Curve's contract address => depositing here
    address public curve;
    address public constant mintr = 0xd061D61a4d941c39E5453435B6345Dc261C2fcE0;

    // stablecoins
    address public constant dai = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address public constant usdc = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address public constant usdt = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address public constant susd = 0x57Ab1ec28D129707052df4dF418D58a2D46d5f51;

    // bitcoins
    address public constant wbtc = 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;
    address public constant renbtc = 0xEB4C2781e4ebA804CE9a9803C67d0893436bB27D;

    // rewards
    address public constant crv = 0xD533a949740bb3306d119CC777fa900bA034cd52;

    // How much CRV tokens to keep
    uint256 public keepCRV = 500;
    uint256 public keepCRVMax = 10000;

    constructor(
        // Curve's contract address => depositing here
        address _curve,
        address _gauge,
        // Token accepted by the contract
        address _want,
        address _governance,
        address _strategist,
        address _controller,
        address _neuronTokenAddress,
        address _timelock
    )
        StrategyBase(
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
