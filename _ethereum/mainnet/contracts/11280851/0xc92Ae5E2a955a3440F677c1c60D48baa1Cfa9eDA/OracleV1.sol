// SPDX-License-Identifier: MIT
pragma solidity ^0.6.11;

contract OracleV1 {
    /// @notice Get the exchange rate between ETH and CETH2. In v1, always return 1e18.
    /// @return The exchange rate.
    function exchangeRate() external view returns (uint) {
        return 1e18;
    }
}
