// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

import "./IERC20.sol";

contract FlyzStakingWarmup {
    address public immutable staking;
    address public immutable sFLYZ;

    constructor(address _staking, address _sFLYZ) {
        require(_staking != address(0));
        staking = _staking;
        require(_sFLYZ != address(0));
        sFLYZ = _sFLYZ;
    }

    function retrieve(address _staker, uint256 _amount) external {
        require(msg.sender == staking);
        IERC20(sFLYZ).transfer(_staker, _amount);
    }
}
