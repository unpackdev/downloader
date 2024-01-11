// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./Address.sol";

contract HeroInfinityMulticall {
  struct Call {
    address target;
    bytes callData;
  }

  function multicall(Call[] memory calls)
    external
    virtual
    returns (bytes[] memory results)
  {
    results = new bytes[](calls.length);
    for (uint256 i = 0; i < calls.length; i++) {
      (bool success, bytes memory ret) = calls[i].target.call(
        calls[i].callData
      );
      require(success, "Multicall: failed");
      results[i] = ret;
    }
    return results;
  }
}
