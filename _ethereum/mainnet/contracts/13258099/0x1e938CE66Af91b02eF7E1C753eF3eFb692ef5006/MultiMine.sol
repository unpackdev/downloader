// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "./IMarzResources.sol";

contract MultiMine {
    address private resources;

    constructor(address _resources) {
        resources = _resources;
    }

    function mine(uint256[] calldata plotIds) external {
        IMarzResources _resources = IMarzResources(resources);

        for (uint256 i = 0; i < plotIds.length; i++) {
            _resources.mine(plotIds[i]);
        }
    }
}
