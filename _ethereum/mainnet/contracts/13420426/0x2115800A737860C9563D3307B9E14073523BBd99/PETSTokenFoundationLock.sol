// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./PETSTokenLock2Rates2Unlocks.sol";

contract PETSTokenFoundationLock is PETSTokenLock2Rates2Unlocks {

    constructor(address _petsTokenAddress) PETSTokenLock2Rates2Unlocks(_petsTokenAddress){
        name = "Foundation";
        maxCap = 15000000 ether;
        numberLockedMonths1 = 1; 
        numberLockedMonths2 = 6;
        numberUnlockingMonths1 = 2;
        unlockPerMonth1 = 750000 ether;
        numberUnlockingMonths2 = 9;
        unlockPerMonth2 = 1500000 ether;
    }

}