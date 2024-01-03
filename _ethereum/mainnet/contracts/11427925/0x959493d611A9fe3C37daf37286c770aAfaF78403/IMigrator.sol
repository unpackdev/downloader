//SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.6.12;

interface IMigrator {
    event ContractMigrated(
        address indexed migrator,
        address indexed oldContract,
        address indexed newContract
    );

    function migrate(
        address oldContract,
        address newContract,
        bytes calldata extraData
    ) external returns (address);
}
