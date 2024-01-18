// SPDX-License-Identifier: MIT
pragma solidity >=0.6.2 <0.9.0;

import "./Common.sol";
import "./test.sol";
// forgefmt: disable-next-line
import "./Components.sol";

abstract contract TestBase is CommonBase {}

abstract contract Test is TestBase, DSTest, StdAssertions, StdCheats, StdUtils {}
