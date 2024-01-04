// SPDX-License-Identifier: MIT
pragma solidity 0.7.4;

import "./SafeMath.sol";
import "./IEPriceOracle.sol";
import "./Library.sol";

/**
 * @title Elysia's price feed
 * @notice Elysia server set EL Price regularlry
 * @author Elysia
 */
contract EPriceOracleEL is IEPriceOracle {

    /// @notice Emitted when el Price is changed
    event NewElPrice(uint256 newElPrice);

    // USD per Elysia token
    // decimals: 18
    uint256 private _elPrice;

    address public admin;

    constructor() {
        admin = msg.sender;
    }

    function getPrice() external view override returns (uint256) {
        return _elPrice;
    }

    function setElPrice(uint256 elPrice_) external returns (bool) {
        require(msg.sender == admin, "Restricted to admin.");

        _elPrice = elPrice_;
        emit NewElPrice(elPrice_);

        return true;
    }
}
