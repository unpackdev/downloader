// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

interface IGovernanceMessageEmitter {
    function resumeActor(address sentinel, bytes1 registrationKind) external;

    function slashActor(address actor, bytes1 registrationKind) external;

    function propagateActors(address[] calldata sentinels, address[] calldata guardians) external;

    function propagateGuardians(address[] calldata guardians) external;

    function propagateSentinels(address[] calldata sentinels) external;
}
