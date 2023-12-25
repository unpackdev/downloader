// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

import "./IERC20.sol";
import "./IStaking.sol";

contract StakingHelper {
    address public immutable staking;
    address public immutable Sync;

    constructor(address _staking, address _Sync) {
        require(_staking != address(0));
        staking = _staking;
        require(_Sync != address(0));
        Sync = _Sync;
    }

    function stake(uint _amount, address recipient) external {
        IERC20(Sync).transferFrom(msg.sender, address(this), _amount);
        IERC20(Sync).approve(staking, _amount);
        IStaking(staking).stake(_amount, recipient);
        IStaking(staking).claim(recipient);
    }
}
