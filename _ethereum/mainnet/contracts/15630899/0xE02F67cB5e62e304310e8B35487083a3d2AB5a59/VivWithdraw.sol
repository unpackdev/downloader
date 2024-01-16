// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;
import "./SafeERC20.sol";
import "./Address.sol";
import "./AccessControl.sol";
import "./TimelockController.sol";

contract VivWithdraw is AccessControl {

    bytes32 public constant WITHDRAW_ADMIN_ROLE = keccak256("WITHDRAW_ADMIN_ROLE");

    using SafeERC20 for IERC20;
    using Address for address payable;

    event Transfer(address indexed from, address indexed to, uint256 value);

    /// @dev timelock has admin role
    /// @param _timelock timelock's proposer is a governor
    constructor(TimelockController _timelock) {
        _setRoleAdmin(WITHDRAW_ADMIN_ROLE, WITHDRAW_ADMIN_ROLE);
        _setupRole(WITHDRAW_ADMIN_ROLE, address(_timelock));
    }

    receive() external payable {}

    /// @dev Transfer
    /// @param to Target address.
    /// @param value Proposal value.
    /// @param token Zero address means ether, otherwise means erc20 token.
    function transfer(
        address to,
        uint256 value,
        address token
    )   external 
        onlyRole(WITHDRAW_ADMIN_ROLE)
    {
        require(to != address(0), "VIV1401");
        require(value > 0, "VIV0001");

        if (token == address(0)) {
            require(address(this).balance >= value, "VIV0036");
        } else {
            require(IERC20(token).balanceOf(address(this)) >= value, "VIV0037");
        }
        if (token == address(0)) {
            payable(to).sendValue(value);
            emit Transfer(address(this), to, value);
        } else {
            IERC20(token).safeTransfer(to, value);
        }
    }
}