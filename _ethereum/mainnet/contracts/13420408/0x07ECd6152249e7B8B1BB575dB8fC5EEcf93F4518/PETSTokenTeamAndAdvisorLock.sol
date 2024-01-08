// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./PETSTokenLock.sol";

contract PETSTokenTeamAndAdvisorLock is PETSTokenLock {

    constructor(address _petsTokenAddress) PETSTokenLock(_petsTokenAddress){
        name = "Team And Advisor";
        maxCap = 15000000 ether;
        numberLockedMonths = 6; 
        numberUnlockingMonths = 10;
        unlockPerMonth = 1500000 ether;
    }

}