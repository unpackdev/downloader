// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Lo.sol";

contract Hi is Lo {
  function say() public override pure returns (string memory) {
    return 'Hi';
  }
}