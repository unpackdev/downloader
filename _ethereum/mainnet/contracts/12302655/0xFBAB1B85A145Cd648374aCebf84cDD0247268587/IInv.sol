// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;
import "./IERC20.sol";

interface IInv is IERC20 {
    function delegate(address delegatee) external;
}
