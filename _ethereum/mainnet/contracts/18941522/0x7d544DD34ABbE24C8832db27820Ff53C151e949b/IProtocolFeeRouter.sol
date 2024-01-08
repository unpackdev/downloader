// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "./IProtocolFees.sol";

interface IProtocolFeeRouter {
  function protocolFees() external view returns (IProtocolFees);
}
