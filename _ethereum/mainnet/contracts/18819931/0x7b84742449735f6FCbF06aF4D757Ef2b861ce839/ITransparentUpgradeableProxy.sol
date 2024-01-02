// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;
import "./IERC1967.sol";

interface ITransparentUpgradeableProxy is IERC1967 {
    function changeAdmin(address) external;
}