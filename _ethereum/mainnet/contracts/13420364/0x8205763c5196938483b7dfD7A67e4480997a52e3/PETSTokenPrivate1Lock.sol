// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./PETSTokenLock.sol";

contract PETSTokenPrivate1Lock is PETSTokenLock {

    constructor(address _petsTokenAddress) PETSTokenLock(_petsTokenAddress){
        name = "Private1";
        maxCap = 6750000 ether;
        numberLockedMonths = 2; 
        numberUnlockingMonths = 9;
        unlockPerMonth = 750000 ether;
    }

}