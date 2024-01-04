// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;

library OracleInterfaces {
  bytes32 public constant Oracle = 'Oracle';
  bytes32 public constant IdentifierWhitelist = 'IdentifierWhitelist';
  bytes32 public constant Store = 'Store';
  bytes32 public constant FinancialContractsAdmin = 'FinancialContractsAdmin';
  bytes32 public constant Registry = 'Registry';
  bytes32 public constant CollateralWhitelist = 'CollateralWhitelist';
  bytes32 public constant OptimisticOracle = 'OptimisticOracle';
}
