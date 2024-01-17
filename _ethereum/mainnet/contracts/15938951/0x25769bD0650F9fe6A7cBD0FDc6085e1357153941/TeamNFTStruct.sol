// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./StageEnum.sol";

struct TeamNFT{
    string teamId;
    TournamentStageEnum stage; //the stage that this team is currently at
}