// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import "./console.sol";
import "./IPriceOracle.sol";

contract ManualPriceOracle is IPriceOracle {
    event NewAdmin(address oldAdmin, address newAdmin);
    event NewPendingAdmin(address oldPendingAdmin, address newPendingAdmin);

    event SetPrice(address underlying, uint64 maturity, int256 price);

    address public admin;
    address public pendingAdmin;

    //voucher => maturity => price
    mapping(address => mapping(uint256 => int256)) public manualPrice;

    modifier onlyAdmin() {
        require(msg.sender == admin, "only admin");
        _;
    }

    constructor() {
        admin = msg.sender;
    }

    function _setPrice(
        address underlying_,
        uint64 maturity_,
        int256 price_
    ) external onlyAdmin {
        manualPrice[underlying_][maturity_] = price_;
        emit SetPrice(underlying_, maturity_, price_);
    }

    function refreshPrice(
        address underlying_,
        uint64 fromDate_,
        uint64 toDate_
    ) external override {}

    function getPrice(
        address underlying_,
        uint64 fromDate_,
        uint64 toDate_
    ) external view override returns (int256) {
        fromDate_;
        return manualPrice[underlying_][toDate_];
    }

    function setPendingAdmin(address newPendingAdmin) external {
        require(msg.sender == admin, "only admin");

        // Save current value, if any, for inclusion in log
        address oldPendingAdmin = pendingAdmin;

        // Store pendingAdmin with value newPendingAdmin
        pendingAdmin = newPendingAdmin;

        // Emit NewPendingAdmin(oldPendingAdmin, newPendingAdmin)
        emit NewPendingAdmin(oldPendingAdmin, newPendingAdmin);
    }

    function acceptAdmin() external {
        require(
            msg.sender == pendingAdmin && msg.sender != address(0),
            "only pending admin"
        );

        // Save current values for inclusion in log
        address oldAdmin = admin;
        address oldPendingAdmin = pendingAdmin;

        // Store admin with value pendingAdmin
        admin = pendingAdmin;

        // Clear the pending value
        pendingAdmin = address(0);

        emit NewAdmin(oldAdmin, admin);
        emit NewPendingAdmin(oldPendingAdmin, pendingAdmin);
    }
}
