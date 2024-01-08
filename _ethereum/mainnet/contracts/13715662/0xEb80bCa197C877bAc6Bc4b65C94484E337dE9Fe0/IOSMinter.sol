// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

import "./ILazyInitCapableElement.sol";

interface IOSMinter is ILazyInitCapableElement {
    function mint(uint256 value, address receiver) external;
}