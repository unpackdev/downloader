pragma solidity 0.8.2;

import "./PolygonStrategyBase.sol";

abstract contract PolygonStrategyStakingRewardsBase is PolygonStrategyBase {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    address public rewards;

    // **** Getters ****
    constructor(
        address _rewards,
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
        rewards = _rewards;
    }

    function balanceOfPool() public view override returns (uint256) {
        return IStakingRewards(rewards).balanceOf(address(this));
    }

    function getHarvestable() external view returns (uint256) {
        return IStakingRewards(rewards).earned(address(this));
    }

    // **** Setters ****

    function deposit() public override {
        uint256 _want = IERC20(want).balanceOf(address(this));
        if (_want > 0) {
            IERC20(want).safeApprove(rewards, 0);
            IERC20(want).safeApprove(rewards, _want);
            IStakingRewards(rewards).stake(_want);
        }
    }

    function _withdrawSome(uint256 _amount)
        internal
        override
        returns (uint256)
    {
        IStakingRewards(rewards).withdraw(_amount);
        return _amount;
    }
}
