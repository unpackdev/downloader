// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import "./IERC20.sol";
import "./ReentrancyGuard.sol";

contract Middleman is ReentrancyGuard {

    constructor(address _allowanceTarget) {
        allowanceTarget = _allowanceTarget;
    }

    address immutable public allowanceTarget;

    function doThing (address contr, bytes calldata action, address receiver, address tokenSend, uint256 amount, address tokenReceive) external payable nonReentrant {
        if (tokenSend != 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE) {
            require(msg.value == 0, "Cannot send ether while swapping token");
            IERC20(tokenSend).transferFrom(msg.sender, address(this), amount);
            if (IERC20(tokenSend).allowance(address(this), allowanceTarget) < amount) {
                IERC20(tokenSend).approve(allowanceTarget, type(uint256).max);
            }
        }
        (bool success, ) = contr.call{value: msg.value}(action);
        require(success);
        if (tokenReceive != 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE) {
            IERC20(tokenReceive).transfer(receiver, IERC20(tokenReceive).balanceOf(address(this)));
        } else {
            payable(receiver).transfer(address(this).balance);
        }
    }
}