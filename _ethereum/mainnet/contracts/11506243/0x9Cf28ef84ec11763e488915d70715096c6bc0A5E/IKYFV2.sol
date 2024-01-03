// SPDX-License-Identifier: MIT

pragma solidity ^0.5.16;

interface IKYFV2 {

    function checkVerified(
        address _user
    )
        external
        view
        returns (bool);

}