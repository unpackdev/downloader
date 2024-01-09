// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

import "./IERC20.sol";
import "./IFlyzStaking.sol";

contract FlyzStakingHelper {
    address public immutable staking;
    address public immutable FLYZ;

    constructor(address _staking, address _FLYZ) {
        require(_staking != address(0));
        staking = _staking;
        require(_FLYZ != address(0));
        FLYZ = _FLYZ;
    }

    function stake(uint256 _amount, address _recipient) external {
        IERC20(FLYZ).transferFrom(msg.sender, address(this), _amount);
        IERC20(FLYZ).approve(staking, _amount);
        IFlyzStaking(staking).stake(_amount, _recipient);
        IFlyzStaking(staking).claim(_recipient);
    }
}
