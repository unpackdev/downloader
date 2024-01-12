// SPDX-License-Identifier: Apache-2.0

pragma solidity =0.8.9;
import "./IRocketEth.sol";
import "./IRocketNetworkBalances.sol";
import "./IRateOracle.sol";

interface IRocketPoolRateOracle is IRateOracle {

    /// @notice Gets the address of the RocketNetworkBalances
    /// @return Address of the RocketNetworkBalances
    function rocketNetworkBalances() external view returns (IRocketNetworkBalances);

    /// @notice Gets the address of the RocketPool RETH token
    /// @return Address of the RocketPool RETH token
    function rocketEth() external view returns (IRocketEth);
}