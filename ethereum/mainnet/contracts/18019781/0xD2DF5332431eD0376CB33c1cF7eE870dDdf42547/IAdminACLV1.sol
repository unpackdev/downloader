// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

abstract contract IAdminACLV1 {
    function allowed(
        address _sender,
        address /*_contract*/,
        bytes4 _selector
    ) external view virtual returns (bool);
}
