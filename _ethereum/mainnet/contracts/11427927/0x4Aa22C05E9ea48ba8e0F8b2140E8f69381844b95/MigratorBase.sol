//SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.6.12;

// Contracts
import "./Base.sol";

// Libraries

// Interfaces
import "./IMigrator.sol";

abstract contract MigratorBase is Base {
    /* Constant Variables */

    /* State Variables */

    address private migrator;

    /* Modifiers */

    /* Constructor */

    constructor(address settingsAddress) internal Base(settingsAddress) {}

    /* External Functions */

    function setMigrator(address newMigrator) external onlyOwner(msg.sender) {
        require(newMigrator.isContract(), "MIGRATOR_MUST_BE_CONTRACT");
        migrator = newMigrator;
    }

    function migrateTo(address newContract, bytes calldata extraData)
        external
        onlyOwner(msg.sender)
    {
        require(newContract != address(0x0), "MIGRATOR_IS_EMPTY");
        IMigrator(migrator).migrate(address(this), newContract, extraData);
    }

    function hasMigrator() external view returns (bool) {
        return migrator != address(0x0);
    }

    /** Internal Functions */

    function _migrator() internal view returns (address) {
        return migrator;
    }
}
