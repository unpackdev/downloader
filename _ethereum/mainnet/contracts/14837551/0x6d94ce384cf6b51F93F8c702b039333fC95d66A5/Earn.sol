// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./Context.sol";
import "./SafeERC20.sol";
import "./IEarnDrip.sol";
import "./IVesperPool.sol";
import "./Strategy.sol";

abstract contract Earn is Strategy {
    using SafeERC20 for IERC20;

    address public immutable dripToken;

    uint256 public dripPeriod = 48 hours;
    uint256 public totalEarned; // accounting total stable coin earned after fee. This amount is not reported to pool.

    event DripPeriodUpdated(uint256 oldDripPeriod, uint256 newDripPeriod);

    constructor(address _dripToken) {
        require(_dripToken != address(0), "dripToken-zero");
        dripToken = _dripToken;
    }

    /**
     * @notice Update update period of distribution of earning done in one rebalance
     * @dev _dripPeriod in seconds
     */
    function updateDripPeriod(uint256 _dripPeriod) external onlyGovernor {
        require(_dripPeriod > 0, "dripPeriod-zero");
        require(_dripPeriod != dripPeriod, "same-dripPeriod");
        emit DripPeriodUpdated(dripPeriod, _dripPeriod);
        dripPeriod = _dripPeriod;
    }

    /// @dev Approves EarnDrip' Grow token to spend dripToken
    function approveGrowToken() external onlyKeeper {
        address _dripContract = IVesperPool(pool).poolRewards();
        address _growPool = IEarnDrip(_dripContract).growToken();
        // Checks that the Grow Pool supports dripToken as underlying
        if (_growPool != address(0)) {
            require(address(IVesperPool(_growPool).token()) == dripToken, "invalid-grow-pool");
            IERC20(dripToken).safeApprove(_growPool, 0);
            IERC20(dripToken).safeApprove(_growPool, MAX_UINT_VALUE);
        }
    }

    /// @dev Converts excess collateral earned to drip token
    function _convertCollateralToDrip(uint256 _collateralAmount) internal {
        if (_collateralAmount > 0) {
            uint256 minAmtOut =
                (swapSlippage != 10000)
                    ? _calcAmtOutAfterSlippage(
                        _getOracleRate(_simpleOraclePath(address(collateralToken), dripToken), _collateralAmount),
                        swapSlippage
                    )
                    : 1;
            _safeSwap(address(collateralToken), dripToken, _collateralAmount, minAmtOut);
        }
    }

    /// @dev Send earning to drip contract.
    function _forwardEarning() internal virtual {
        uint256 _earned = IERC20(dripToken).balanceOf(address(this));
        if (_earned > 0) {
            address _dripContract = IVesperPool(pool).poolRewards();
            // Fetches which rewardToken collects the drip
            address _growPool = IEarnDrip(_dripContract).growToken();
            totalEarned += _earned;
            // Checks that the Grow Pool supports dripToken as underlying
            if (_growPool != address(0) && address(IVesperPool(_growPool).token()) == dripToken) {
                uint256 _growPoolBalanceBefore = IERC20(_growPool).balanceOf(address(this));
                IVesperPool(_growPool).deposit(_earned);
                uint256 _growPoolShares = IERC20(_growPool).balanceOf(address(this)) - _growPoolBalanceBefore;
                IERC20(_growPool).safeTransfer(_dripContract, _growPoolShares);
                IEarnDrip(_dripContract).notifyRewardAmount(_growPool, _growPoolShares, dripPeriod);
            } else {
                IERC20(dripToken).safeTransfer(_dripContract, _earned);
                IEarnDrip(_dripContract).notifyRewardAmount(dripToken, _earned, dripPeriod);
            }
        }
    }

    /** @dev Handle collateral profit.
     *      Calculate fee on profit.
     *      Transfer fee to feeCollector
     *      Convert remaining profit into drip token
     *      Forward drip token earning to EarnDrip
     * @param _profit Profit in collateral
     */
    function _handleProfit(uint256 _profit) internal virtual {
        if (_profit > 0) {
            uint256 _fee = IVesperPool(pool).calculateUniversalFee(_profit);
            if (_fee > 0) {
                collateralToken.safeTransfer(feeCollector, _fee);
                // Calculated fee will always be less than _profit
                _profit -= _fee;
            }
            _convertCollateralToDrip(_profit);
            _forwardEarning();
        }
    }
}
