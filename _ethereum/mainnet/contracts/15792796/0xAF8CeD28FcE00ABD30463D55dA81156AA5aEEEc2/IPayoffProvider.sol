// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

import "./Fixed18.sol";
import "./IOracleProvider.sol";
import "./PayoffDefinition.sol";

interface IPayoffProvider {
    error PayoffProviderInvalidOracle();
    error PayoffProviderInvalidPayoffDefinitionError();

    function oracle() external view returns (IOracleProvider);
    function payoffDefinition() external view returns (PayoffDefinition memory);
    function currentVersion() external view returns (IOracleProvider.OracleVersion memory);
    function atVersion(uint256 oracleVersion) external view returns (IOracleProvider.OracleVersion memory);
}
