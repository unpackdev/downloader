//SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./IPaymentStreamFactory.sol";

interface IPaymentStreamFactoryMetadata is IPaymentStreamFactory {
  // solhint-disable func-name-mixedcase
  function NAME() external view returns (string memory);

  function VERSION() external view returns (string memory);
}
