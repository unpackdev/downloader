// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.15;

import "./APMorganMinter.sol";

contract APMorganMinterDeployable is APMorganMinter {
    constructor(
        address _networkVrfCoordinator,
        address _linkToken,
        bytes32 _keyHash
    ) APMorganMinter(false, _networkVrfCoordinator, _linkToken, _keyHash) {}
}

contract APMorganMinterTestNet is APMorganMinterDeployable {
    constructor(
        address _networkVrfCoordinator,
        address _linkToken,
        bytes32 _keyHash
    ) APMorganMinterDeployable(_networkVrfCoordinator, _linkToken, _keyHash) {}
}
