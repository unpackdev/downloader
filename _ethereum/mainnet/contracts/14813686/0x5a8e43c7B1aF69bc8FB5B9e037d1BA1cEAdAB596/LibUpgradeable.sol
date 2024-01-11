// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

library HelpersUpgradeable {
    // constants
    bytes32 private constant BONUS_TYPEHASH =
        keccak256(
            "CustomFee(address sharesOwner,uint256 amount,uint256 deadline,uint256 fee)"
        );
    bytes32 private constant CONTRACT_UPDATER = keccak256("CONTRACT_UPDATER");
    bytes32 private constant TREASURY = keccak256("TREASURY");
    bytes32 private constant BONUS_REWARDER = keccak256("BONUS_REWARDER");

    uint256 constant UNLIMITED_APPROVAL = type(uint256).max;
    // Sentinal values used to save gas on deposit/withdraw/migrate
    // NOTE: DEPOSIT_EVERYTHING == WITHDRAW_EVERYTHING == MIGRATE_EVERYTHING
    uint256 constant DEPOSIT_EVERYTHING = type(uint256).max;
    uint256 constant WITHDRAW_EVERYTHING = type(uint256).max;

    uint256 constant MIGRATE_EVERYTHING = type(uint256).max;
    // VaultsAPI.depositLimit is unlimited
    uint256 constant UNCAPPED_DEPOSITS = type(uint256).max;

    function getBonusTypeHash() internal pure returns (bytes32) {
        return BONUS_TYPEHASH;
    }

    function getContractUpdaterRoleId() internal pure returns (bytes32) {
        return CONTRACT_UPDATER;
    }

    function getTreasuryRoleId() internal pure returns (bytes32) {
        return TREASURY;
    }

    function getBonusRewarderRoleId() internal pure returns (bytes32) {
        return BONUS_REWARDER;
    }

    function getUnlimitedApprovalAmount() internal pure returns (uint256) {
        return UNLIMITED_APPROVAL;
    }

    function getDepositEverythingAmount() internal pure returns (uint256) {
        return DEPOSIT_EVERYTHING;
    }

    function getWithdrawEverythingAmount() internal pure returns (uint256) {
        return WITHDRAW_EVERYTHING;
    }

    function getMigrateEverythingAmount() internal pure returns (uint256) {
        return MIGRATE_EVERYTHING;
    }

    function getUncappedDepositsAmount() internal pure returns (uint256) {
        return UNCAPPED_DEPOSITS;
    }
}
