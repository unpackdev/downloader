// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IMigratablePool.sol";

/**
 * @dev Deri Protocol migratable pool implementation
 */
abstract contract MigratablePool is IMigratablePool {

    // Controller address
    address _controller;

    // Migration timestamp of this pool, zero means not set
    // Migration timestamp can only be set with a grace period at least 3 days, and the
    // `migrationDestination` pool address must be also set when setting migration timestamp,
    // users can use this grace period to verify the `migrationDestination` pool code
    uint256 _migrationTimestamp;

    // The new pool this pool will migrate to after grace period, zero address means not set
    address _migrationDestination;

    modifier _controller_() {
        require(msg.sender == _controller, "can only be called by current controller");
        _;
    }

    /**
     * @dev See {IMigratablePool}.{setController}
     */
    function setController(address newController) public override {
        require(newController != address(0), "MigratablePool: setController to 0 address");
        require(
            _controller == address(0) || msg.sender == _controller,
            "MigratablePool: setController can only be called by current controller or not set"
        );
        _controller = newController;
    }

    /**
     * @dev See {IMigratablePool}.{controller}
     */
    function controller() public view override returns (address) {
        return _controller;
    }

    /**
     * @dev See {IMigratablePool}.{migrationTimestamp}
     */
    function migrationTimestamp() public view override returns (uint256) {
        return _migrationTimestamp;
    }

    /**
     * @dev See {IMigratablePool}.{migrationDestination}
     */
    function migrationDestination() public view override returns (address) {
        return _migrationDestination;
    }

    /**
     * @dev See {IMigratablePool}.{prepareMigration}
     */
    function prepareMigration(address newPool, uint256 graceDays) public override _controller_ {
        require(newPool != address(0), "MigratablePool: prepareMigration to 0 address");
        require(graceDays >= 3 && graceDays <= 365, "MigratablePool: graceDays must be 3-365 days");

        _migrationTimestamp = block.timestamp + graceDays * 1 days;
        _migrationDestination = newPool;

        emit PrepareMigration(_migrationTimestamp, address(this), _migrationDestination);
    }

    /**
     * @dev See {IMigratablePool}.{approveMigration}
     *
     * This function will be implemented in inheriting contract
     * This function will change if there is an upgrade to existent pool
     */
    // function approveMigration() public virtual override _controller_ {}

    /**
     * @dev See {IMigratablePool}.{executeMigration}
     *
     * This function will be implemented in inheriting contract
     * This function will change if there is an upgrade to existent pool
     */
    // function executeMigration(address source) public virtual override _controller_ {}

}
