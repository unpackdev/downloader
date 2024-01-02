// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

import "./ChainlinkOracleImpl.sol";

/// @title Oracle factory interface
interface IChainlinkOracleFactory {
    /// -----------------------------------------------------------------------
    /// events
    /// -----------------------------------------------------------------------

    event CreateChainlinkOracle(address indexed oracle, ChainlinkOracleImpl.InitParams params);

    /// -----------------------------------------------------------------------
    /// functions - public & external
    /// -----------------------------------------------------------------------

    /**
     * @notice Create a new Chainlink Oracle
     * @param data_ abi encoded initial chainlink oracle params
     * @param salt_ user defined salt
     * @return oracle The oracle address
     */
    function createOracle(bytes calldata data_, bytes32 salt_) external returns (address);

    /**
     * @notice Predict the address of a new Chainlink Oracle
     * @param data_ abi encoded initial chainlink oracle params
     * @param salt_ user defined salt
     * @return oracle The oracle address
     */
    function predictDeterministicAddress(bytes calldata data_, bytes32 salt_) external view returns (address);

    /**
     * @notice Check if a Chainlink Oracle is deployable
     * @param data_ abi encoded initial chainlink oracle params
     * @param salt_ user defined salt
     * @return address The oracle address
     * @return is_deployed True if the oracle is already deployed
     */
    function isDeployed(bytes calldata data_, bytes32 salt_) external view returns (address, bool);

    /// @notice The oracle implementation
    function oracleImplementation() external view returns (address);
}
