pragma experimental ABIEncoderV2;
// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "./PreprocessorLib.sol";

contract Preprocessor {
  using PreprocessorLib for *;
  function destroy() external {
    selfdestruct(msg.sender);
  }
}
