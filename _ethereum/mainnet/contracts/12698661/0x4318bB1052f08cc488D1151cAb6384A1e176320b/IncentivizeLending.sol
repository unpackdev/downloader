// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "./Executor.sol";

import "./Lending.sol";

contract IncentivizeLending is Executor {
    address[] tokens;
    uint256[] amounts;
    uint256 endTimestamp;

    constructor(
        address[] memory _tokens,
        uint256[] memory _amounts,
        uint256 _endTimestamp,
        address _roles
    ) RoleAware(_roles) {
        tokens = _tokens;
        amounts = _amounts;
        endTimestamp = _endTimestamp;
    }


    function requiredRoles()
        external
        override
        returns (uint256[] memory required)
    {}

    function execute() external override {
        uint256 tstamp = endTimestamp;
        for (uint256 i; tokens.length > i; i++) {
            Lending(lending()).addIncentive(tokens[i], amounts[i], tstamp);
        }
    }
}