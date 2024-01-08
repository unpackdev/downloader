// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

//Contract deployed by LK Tech Club Incubator 2021 dba Lift.Kitchen - 4/24/2021

import "./IERC20.sol";
import "./SafeERC20.sol";

import "./Operator.sol";
import "./ISimpleERCFund.sol";

contract DevFund is ISimpleERCFund, Operator {
    using SafeERC20 for IERC20;

    function deposit(
        address token,
        uint256 amount,
        string memory reason
    ) public override {
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        emit Deposit(msg.sender, block.timestamp, reason);
    }

    function withdraw(
        address token,
        uint256 amount,
        address to,
        string memory reason
    ) public override onlyOperator {
        IERC20(token).safeTransfer(to, amount);
        emit Withdrawal(msg.sender, to, block.timestamp, reason);
    }

    event Deposit(address indexed from, uint256 indexed at, string reason);
    event Withdrawal(
        address indexed from,
        address indexed to,
        uint256 indexed at,
        string reason
    );
}
