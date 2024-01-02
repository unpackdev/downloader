// SPDX-License-Identifier: MIT
// Copyright 2023 PROOF Holdings Inc
pragma solidity ^0.8.15;

import "./RoleGatedLimitedProjectId.sol";
import "./Grails5.sol";

contract Grails5LimitedAirdropper is RoleGatedLimitedProjectId {
    constructor(address admin, address steerer, Grails5 grails5, uint64 numMax, address airdropper)
        RoleGatedLimitedProjectId(admin, steerer, grails5, numMax)
    {
        _grantRole(PURCHASER_ROLE, airdropper);
    }
}
