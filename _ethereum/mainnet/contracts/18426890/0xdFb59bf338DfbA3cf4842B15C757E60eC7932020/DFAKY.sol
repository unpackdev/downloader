// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import "./MultiStageBase.sol";

contract DFAKY is MultiStageBase {
  function initialize (Args memory args) public initializer {
    __Base_init(args);
  }
}
