// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./PETSTokenLock.sol";

contract PETSTokenRewardsLock is PETSTokenLock {

    constructor(address _petsTokenAddress) PETSTokenLock(_petsTokenAddress){
        name = "Rewards";
        maxCap = 10000000 ether;
        numberLockedMonths = 1; 
        numberUnlockingMonths = 20;
        unlockPerMonth = 500000 ether;
    }

}