// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "./IVault.sol";
import "./Milestone.sol";
import "./IMintableOwnedERC20.sol";

struct ProjectInitParams {
    address projectTeamWallet;
    IVault vault;
    Milestone[] milestones;
    IMintableOwnedERC20 projectToken;
    uint platformCutPromils;
    uint minPledgedSum;
    uint onChangeExitGracePeriod;
    uint pledgerGraceExitWaitTime;
    address paymentToken;
    bytes32 cid;
}
