// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.9;

interface IVaultReserve {
    event Deposit(address indexed vault, address indexed token, uint256 amount);
    event Withdraw(address indexed vault, address indexed token, uint256 amount);
    event VaultListed(address indexed vault);

    function deposit(address token, uint256 amount) external payable returns (bool);

    function whitelistVault(address vault) external returns (bool);

    function withdraw(address token, uint256 amount) external returns (bool);

    function isWhitelisted(address vault) external view returns (bool);

    function getBalance(address vault, address token) external view returns (uint256);
}
