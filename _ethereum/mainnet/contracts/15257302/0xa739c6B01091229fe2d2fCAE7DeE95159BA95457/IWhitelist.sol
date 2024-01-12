//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./IERC20.sol";

/**
 * @title ICallable
 * @author clement.saunier@b2expand.com
 */
abstract contract IWhitelist {
    function hasAccess(address addr) external virtual returns (bool access);
}
