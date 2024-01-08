// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

import "./IERC20.sol";

interface IStaking {
    function stake(uint256 _amount, address _recipient) external returns (bool);

    function claim(address _recipient) external;
}

contract AxeStakingHelper {
    address public immutable staking;
    address public immutable AXE;

    constructor(address _staking, address _AXE) {
        require(_staking != address(0));
        staking = _staking;
        require(_AXE != address(0));
        AXE = _AXE;
    }

    function stake(uint256 _amount, address _recipient) external {
        IERC20(AXE).transferFrom(msg.sender, address(this), _amount);
        IERC20(AXE).approve(staking, _amount);
        IStaking(staking).stake(_amount, _recipient);
        IStaking(staking).claim(_recipient);
    }
}
