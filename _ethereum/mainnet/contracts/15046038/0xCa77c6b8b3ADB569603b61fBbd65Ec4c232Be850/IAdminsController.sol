//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./IAdmins.sol";

interface IAdminsController {
    function changeAdmins(IAdmins _newAdmins) external;
}
