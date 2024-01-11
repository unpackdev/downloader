// SPDX-License-Identifier: WTFPL

pragma solidity >=0.5.0;

interface IETHVault {
    event Receive(address indexed sender, uint256 amount);
    event SetOperator(address indexed account, bool isOperator);
    event Withdraw(address indexed operator, uint256 amount, address to);

    function isOperator(address account) external view returns (bool);

    function setOperator(address account, bool _isOperator) external;

    function withdraw(uint256 amount, address to) external;
}
