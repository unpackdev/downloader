// SPDX-License-Identifier: MIT

pragma solidity 0.8.3;

import "./Context.sol";
import "./SafeERC20.sol";
import "./IPoolRewards.sol";
import "./IVesperPool.sol";
import "./console.sol";

abstract contract Earn is Context {
    using SafeERC20 for IERC20;
    uint256 public dripPeriod = 48 hours;
    uint256 public totalEarned; // accounting total stable coin earned. This amount is not reported to pool.

    /**
     * @notice Send this earning to drip contract.
     */
    function _forwardEarning(
        address _token,
        address _feeCollector,
        address _pool
    ) internal {
        (, uint256 _interestFee, , , , , , ) = IVesperPool(_pool).strategy(address(this));
        address _dripContract = IVesperPool(_pool).poolRewards();
        uint256 _earned = IERC20(_token).balanceOf(address(this));
        if (_earned != 0) {
            totalEarned += _earned;
            uint256 _fee = (_earned * _interestFee) / 10000;
            if (_fee != 0) {
                IERC20(_token).safeTransfer(_feeCollector, _fee);
                _earned = _earned - _fee;
            }
            IERC20(_token).safeTransfer(_dripContract, _earned);
            IPoolRewards(_dripContract).notifyRewardAmount(_earned, dripPeriod);
        }
    }
}
