// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./BasicBoneDistributor.sol";

contract xLeashBoneDistributor is BasicBoneDistributor {
    constructor (IERC20 _bone) BasicBoneDistributor(_bone) public {}
}