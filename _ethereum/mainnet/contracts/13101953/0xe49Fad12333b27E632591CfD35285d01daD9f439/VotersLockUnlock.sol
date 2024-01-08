// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

import "./Voters.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";

contract VotersLockUnlock {
    using SafeERC20 for IERC20;

    function run(address voters, uint amount) public {
        Voters v = Voters(voters);
        IERC20(v.token()).safeTransferFrom(msg.sender, address(this), amount);
        IERC20(v.token()).approve(voters, amount);
        v.lock(amount);
        v.unlock(amount);
    }
}
