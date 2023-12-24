// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.15;

import "./Executable.sol";
import "./UseStore.sol";
import "./OperationStorage.sol";
import "./Spark.sol";
import "./Spark.sol";
import "./IPool.sol";

/**
 * @title SetEMode | Spark Action contract
 * @notice Sets the user's eMode on Spark's lending pool
 */
contract SparkSetEMode is Executable, UseStore {
  using Write for OperationStorage;

  constructor(address _registry) UseStore(_registry) {}

  /**
   * @param data Encoded calldata that conforms to the SetEModeData struct
   */
  function execute(bytes calldata data, uint8[] memory) external payable override {
    SetEModeData memory emode = parseInputs(data);

    IPool(registry.getRegisteredService(SPARK_LENDING_POOL)).setUserEMode(emode.categoryId);

    store().write(bytes32(uint256(emode.categoryId)));
  }

  function parseInputs(bytes memory _callData) public pure returns (SetEModeData memory params) {
    return abi.decode(_callData, (SetEModeData));
  }
}
