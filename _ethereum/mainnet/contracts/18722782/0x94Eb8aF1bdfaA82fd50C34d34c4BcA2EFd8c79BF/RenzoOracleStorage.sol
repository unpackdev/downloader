// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

import "./IRoleManager.sol";
import "./AggregatorV3Interface.sol";
import "./IERC20.sol";

abstract contract RenzoOracleStorageV1 {    
    /// @dev reference to the RoleManager contract
    IRoleManager public roleManager;

    /// @dev The mapping of supported token addresses to their respective Chainlink oracle address
    mapping(IERC20 => AggregatorV3Interface) public tokenOracleLookup;
}
