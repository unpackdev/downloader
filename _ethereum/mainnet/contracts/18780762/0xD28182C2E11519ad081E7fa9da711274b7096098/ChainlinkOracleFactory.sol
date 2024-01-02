// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

import "./BaseChainlinkOracleFactory.sol";
import "./ChainlinkOracleImpl.sol";

/// @title Chainlink Oracle Factory
/// @author 0xSplits
/// @notice Factory for creating Chainlink Oracles
contract ChainlinkOracleFactory is BaseChainlinkOracleFactory {
    /// -----------------------------------------------------------------------
    /// storage - constants & immutables
    /// -----------------------------------------------------------------------

    address public immutable ORACLE;

    /// -----------------------------------------------------------------------
    /// constructor
    /// -----------------------------------------------------------------------

    constructor(address weth9_) {
        ORACLE = address(new ChainlinkOracleImpl(weth9_));
    }

    /// -----------------------------------------------------------------------
    /// functions - public & external
    /// -----------------------------------------------------------------------

    function oracleImplementation() public view override returns (address) {
        return ORACLE;
    }
}
