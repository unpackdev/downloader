// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

import "IERC20.sol";

interface ILockingVault {
    function underlying() external view returns (IERC20);

    function deposit(uint256 _amount) external;

    function deposit(uint256 _amount, address _delegate) external;

    event Deposit(
        address indexed from,
        address indexed delegate,
        uint256 amount
    );

    function initiateWithdrawal(
        uint256 _amount,
        address _delegate
    ) external returns (uint256);

    function withdraw(uint256 withdrawalId) external;

    event WithdrawalQueued(
        uint256 indexed id,
        address indexed to,
        address indexed delegate,
        uint256 withdrawalAt,
        uint256 amount
    );
    event WithdrawalCompleted(
        uint256 indexed id,
        address indexed to,
        uint256 amount
    );
}
