// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.18;

import "./IAccessControl.sol";

interface ICoreAccessControlV1 is IAccessControl {
    function ROLE_CLIENT() external returns (bytes32);

    function ROLE_DEFINITIVE() external returns (bytes32);

    function ROLE_DEFINITIVE_ADMIN() external returns (bytes32);
}
