// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.15;

import "./APMorganMinterDeployable.sol";

contract APMorganMinterMainnet is APMorganMinterDeployable {
    address constant mainnetVrfCoordinator =
        0x271682DEB8C4E0901D1a1550aD2e64D568E69909;
    address constant linkTokenContract =
        0x514910771AF9Ca656af840dff83E8264EcF986CA;
    bytes32 constant keyHashParam =
        0x8af398995b04c28e9951adb9721ef74c74f93e6a478f39e7e0777be13527e7ef;

    constructor()
        APMorganMinterDeployable(
            mainnetVrfCoordinator,
            linkTokenContract,
            keyHashParam
        )
    {}
}
