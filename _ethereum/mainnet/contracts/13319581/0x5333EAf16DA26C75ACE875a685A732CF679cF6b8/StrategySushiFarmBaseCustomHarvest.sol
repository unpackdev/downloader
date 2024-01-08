pragma solidity 0.8.2;

import "./ERC20.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";
import "./Address.sol";
import "./StrategyBase.sol";
import "./ISushiChef.sol";

abstract contract StrategySushiFarmBaseCustomHarvest is StrategyBase {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    // Token addresses
    address public constant sushi = 0x6B3595068778DD592e39A122f4f5a5cF09C90fE2;
    address public constant masterChef =
        0xc2EdaD668740f1aA35E4D8f227fB8E17dcA888Cd;

    // WETH/<token1> pair
    address public token1;

    // How much SUSHI tokens to keep?
    uint256 public keepSUSHI = 0;
    uint256 public constant keepSUSHIMax = 10000;

    uint256 public poolId;

    constructor(
        address _token1,
        uint256 _poolId,
        address _lp,
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
        token1 = _token1;
        IERC20(sushi).safeApprove(sushiRouter, type(uint256).max);
        IERC20(weth).safeApprove(sushiRouter, type(uint256).max);
    }

    function balanceOfPool() public view override returns (uint256) {
        (uint256 amount, ) = ISushiChef(masterChef).userInfo(
            poolId,
            address(this)
        );
        return amount;
    }

    function getHarvestable() external view returns (uint256) {
        return ISushiChef(masterChef).pendingSushi(poolId, address(this));
    }

    // **** Setters ****

    function deposit() public override {
        uint256 _want = IERC20(want).balanceOf(address(this));
        if (_want > 0) {
            IERC20(want).safeApprove(masterChef, 0);
            IERC20(want).safeApprove(masterChef, _want);
            ISushiChef(masterChef).deposit(poolId, _want);
        }
    }

    function _withdrawSome(uint256 _amount)
        internal
        override
        returns (uint256)
    {
        ISushiChef(masterChef).withdraw(poolId, _amount);
        return _amount;
    }

    // **** Setters ****

    function setKeepSUSHI(uint256 _keepSUSHI) external {
        require(msg.sender == timelock, "!timelock");
        keepSUSHI = _keepSUSHI;
    }
}
