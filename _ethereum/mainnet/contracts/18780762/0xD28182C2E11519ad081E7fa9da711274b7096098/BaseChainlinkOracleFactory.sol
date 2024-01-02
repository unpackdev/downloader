// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

import "./LibClone.sol";
import "./IChainlinkOracleFactory.sol";
import "./ChainlinkOracleImpl.sol";

/// @title Base Chainlink Oracle Factory
/// @author 0xSplits
/// @notice Factory for creating Chainlink Oracles
abstract contract BaseChainlinkOracleFactory is IChainlinkOracleFactory {
    /// -----------------------------------------------------------------------
    /// libraries
    /// -----------------------------------------------------------------------

    using LibClone for address;

    /// -----------------------------------------------------------------------
    /// functions - public & external
    /// -----------------------------------------------------------------------

    /// @inheritdoc IChainlinkOracleFactory
    function createOracle(bytes calldata data_, bytes32 salt_) external returns (address oracle) {
        oracle = oracleImplementation().cloneDeterministic(_getSalt(data_, salt_));
        ChainlinkOracleImpl.InitParams memory params = abi.decode(data_, (ChainlinkOracleImpl.InitParams));
        ChainlinkOracleImpl(oracle).initializer(params);
        emit CreateChainlinkOracle({oracle: oracle, params: params});
    }

    /// @inheritdoc IChainlinkOracleFactory
    function predictDeterministicAddress(bytes calldata data_, bytes32 salt_) external view returns (address) {
        return _predictDeterministicAddress(data_, salt_);
    }

    /// @inheritdoc IChainlinkOracleFactory
    function isDeployed(bytes calldata data_, bytes32 salt_) external view returns (address, bool) {
        address oracle = _predictDeterministicAddress(data_, salt_);
        uint256 size;
        assembly {
            size := extcodesize(oracle)
        }
        return (oracle, size > 0);
    }

    function oracleImplementation() public view virtual returns (address oracle_) {}

    /// -----------------------------------------------------------------------
    /// functions - private & internal
    /// -----------------------------------------------------------------------

    function _getSalt(bytes calldata data_, bytes32 salt_) internal pure returns (bytes32) {
        return keccak256(bytes.concat(data_, salt_));
    }

    function _predictDeterministicAddress(bytes calldata data_, bytes32 salt_) internal view returns (address) {
        return oracleImplementation().predictDeterministicAddress(_getSalt(data_, salt_), address(this));
    }
}
