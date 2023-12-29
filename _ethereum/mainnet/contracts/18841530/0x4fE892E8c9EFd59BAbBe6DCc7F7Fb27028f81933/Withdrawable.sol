// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./AccessControl.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";

abstract contract Withdrawable is AccessControl {
    using SafeERC20 for IERC20;

    bytes32 public constant WITHDRAW_ROLE = keccak256("WITHDRAW_ROLE");

    event Withdraw(address indexed token, address indexed to, uint256 amount);

    function withdraw(IERC20 token) public virtual onlyRole(WITHDRAW_ROLE) {
        withdraw(token, msg.sender);
    }

    function withdraw(IERC20 token, address to) public virtual onlyRole(WITHDRAW_ROLE) {
        withdraw(token, to, token.balanceOf(address(this)));
    }

    function withdraw(IERC20 token, uint256 amount) public virtual onlyRole(WITHDRAW_ROLE) {
        withdraw(token, msg.sender, amount);
    }

    function withdraw(IERC20 token, address to, uint256 amount) public virtual onlyRole(WITHDRAW_ROLE) {
        token.safeTransfer(to, amount);
        emit Withdraw(address(token), to, amount);
    }
}
