// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./ShifterPoolQuery.sol";
import "./ShifterPoolLib.sol";

contract ShifterPoolIsolateQuery is ShifterPoolQuery {
  struct ExternalIsolate {
    uint256 genesis;
    address borrowProxyImplementation;
    address assetForwarderImplementation;
    address shifterRegistry;
    uint256 minTimeout;
    uint256 poolFee;
    uint256 daoFee;
    uint256 maxLoan;
  }
  function execute(bytes memory /* context */) public view returns (ExternalIsolate memory) {
    return ExternalIsolate({
      genesis: isolate.genesis,
      borrowProxyImplementation: isolate.borrowProxyImplementation,
      assetForwarderImplementation: isolate.assetForwarderImplementation,
      shifterRegistry: isolate.shifterRegistry,
      minTimeout: isolate.minTimeout,
      poolFee: isolate.poolFee,
      daoFee: isolate.daoFee,
      maxLoan: isolate.maxLoan
    });
  }
}
