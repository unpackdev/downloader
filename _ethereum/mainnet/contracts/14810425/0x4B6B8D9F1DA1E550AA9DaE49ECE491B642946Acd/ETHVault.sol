// SPDX-License-Identifier: WTFPL

pragma solidity ^0.8.13;

import "./Ownable.sol";
import "./IETHVault.sol";

contract ETHVault is Ownable, IETHVault {
    mapping(address => bool) public override isOperator;

    receive() external payable {
        emit Receive(msg.sender, msg.value);
    }

    function setOperator(address account, bool _isOperator) external override onlyOwner {
        isOperator[account] = _isOperator;

        emit SetOperator(account, _isOperator);
    }

    function withdraw(uint256 amount, address to) external override {
        require(isOperator[msg.sender], "EV: FORBIDDEN");

        emit Withdraw(msg.sender, amount, to);

        payable(to).transfer(amount);
    }
}
