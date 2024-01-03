// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.19;

import "./ClaimConfigurable.sol";

contract BrctClaim is ClaimConfigurable {
    // public constant address
    address public constant BRCT = 0x455ad1Bc4E18fD4e369234b6e11D88acBC416758;

    constructor(
        uint256 _claimTime,
        uint256[4] memory _vestingData
    ) ClaimConfigurable(_claimTime, BRCT, _vestingData) {}
}
