//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "./ClaimVaultLib.sol";

contract VaultClaimStorage {
    address public claimer;

    uint256 public lastClaimedRound;

    // for claimer
    uint256 public oneClaimAmountByClaimer;
    uint256 public totalClaimedCountByClaimer;

    // round = time
    mapping(uint256 => uint256) public claimedTimesOfRoundByCliamer;
    bool public startedByClaimer;
}
