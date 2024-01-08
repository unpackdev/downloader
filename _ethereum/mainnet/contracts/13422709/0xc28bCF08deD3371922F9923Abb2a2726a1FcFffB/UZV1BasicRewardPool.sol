// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;
pragma abicoder v2;

import "./SafeMath.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";

import "./SharedDataTypes.sol";
import "./UZV1BasePool.sol";

/**
 * @title UnizenBasicRewardPool
 * @author Unizen
 * @notice Reward pool for ERC20 tokens
 **/
contract UZV1BasicRewardPool is UZV1BasePool {
    using SafeMath for uint256;

    /* === STATE VARIABLES === */

    function initialize(address _router, address _accessToken)
        public
        override
        initializer
    {
        UZV1BasePool.initialize(_router, _accessToken);
    }

    /* === VIEW FUNCTIONS === */
    function canReceiveRewards() external pure override returns (bool) {
        return true;
    }

    function getPoolType() external pure override returns (uint8) {
        return 0;
    }

    function isPayable() public pure override returns (bool) {
        return false;
    }

    function isNative() public pure override returns (bool) {
        return false;
    }

    /* === MUTATING FUNCTIONS === */
    /// user functions
    function _safeClaim(address _user, uint256 _amount)
        internal
        override
        returns (uint256)
    {
        IERC20 _token = IERC20(_poolData.token);
        uint256 _balance = _token.balanceOf(address(this));
        uint256 _realAmount = (_amount <= _balance) ? _amount : _balance;

        if (_realAmount == 0) return 0;

        _poolStakerUser[_user].totalSavedRewards = _poolStakerUser[_user]
            .totalSavedRewards
            .add(_realAmount);

        _totalRewardsLeft = _totalRewardsLeft.sub(_realAmount);

        SafeERC20.safeTransfer(_token, _user, _realAmount);

        emit RewardClaimed(_user, _realAmount);
        return _realAmount;
    }
}
