// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "./Ownable.sol";
import "./ShifterPoolLib.sol";

contract ShifterPoolQuery is Ownable {
  ShifterPoolLib.Isolate isolate;
}
