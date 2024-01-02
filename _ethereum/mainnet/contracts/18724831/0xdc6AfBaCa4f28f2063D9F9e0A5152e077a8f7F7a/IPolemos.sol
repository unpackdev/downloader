// SPDX-License-Identifier: MIT

/*
|   _____            _                                    |
|  |  __ \          | |                                   |
|  | |__) |   ___   | |   ___   _ __ ___     ___    ___   |
|  |  ___/   / _ \  | |  / _ \ | '_ ` _ \   / _ \  / __|  |
|  | |      | (_) | | | |  __/ | | | | | | | (_) | \__ \  |
|  |_|       \___/  |_|  \___| |_| |_| |_|  \___/  |___/  |
|                                                         |
|                                                         |
*/

pragma solidity ^0.8.0;
import "./IERC20.sol";

interface IPolemos is IERC20 {
  function delegate(address delegatee) external;
}
