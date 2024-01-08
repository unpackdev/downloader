// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

abstract contract FundLibrary {
    event Deposit(
        address depositor,
        uint256 depositAmount,
        uint256 sharesEmitted,
        uint256 sharePrice,
        uint256 timestamp
    );

    event Swap(
        address from,
        address to,
        uint256 amount,
        uint256 receivedAmount,
        uint256 timestamp
    );

    event Withdraw(
        address withdrawer,
        uint256 sharesWithdrew,
        uint256 sharePrice,
        uint256 timestamp
    );

    event ManagerUpdated(
        address oldManager,
        string oldName,
        address newManager,
        string newName
    );

    event AssetAdded(
        address asset
    );

    event AssetRemoved(
        address asset
    );

    event ParaswapUpgrade(
        address oldParaswapProxy,
        address oldParaswapAugustus,
        address newParaswapProxy,
        address newParaswapAugustus
    );

    event BuybackVaultUpgrade(
        address oldVault,
        address newVault
    );

    event OracleUpgrade(
        address oldOracle,
        address newOracle
    );

    event FeeMinted(
        uint256 oldSharePrice,
        uint256 newSharePrice,
        uint256 profitUSD,
        uint256 sharesBuybackMinted,
        uint256 sharesManagerMinted,
        uint256 timestamp
    );
}