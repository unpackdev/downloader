// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./PETSTokenLock.sol";

contract PETSTokenPrivate2Lock is PETSTokenLock {

    constructor(address _petsTokenAddress) PETSTokenLock(_petsTokenAddress){
        name = "Private2";
        maxCap = 6800000 ether;
        numberLockedMonths = 2; 
        numberUnlockingMonths = 8;
        unlockPerMonth = 850000 ether;
    }

}