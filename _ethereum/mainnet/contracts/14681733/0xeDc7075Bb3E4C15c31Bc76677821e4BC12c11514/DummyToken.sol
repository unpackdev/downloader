// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;
pragma abicoder v2;

import "./DogeToken.sol";

contract DummyToken is DogeToken {
  event Migration(uint256 version);

  function migrate(uint256 version) public {
    emit Migration(version);
  }

}
