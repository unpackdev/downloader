// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./FeeControllerV2I.sol";

interface FeeControllerV3I is FeeControllerV2I {
    function setAdminAirdropFee(uint256 _adminAirdropFee) external;
}