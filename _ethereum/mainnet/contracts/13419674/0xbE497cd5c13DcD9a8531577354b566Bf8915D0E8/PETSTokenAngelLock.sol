// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./PETSTokenLock.sol";

contract PETSTokenAngelLock is PETSTokenLock {

    constructor(address _petsTokenAddress) PETSTokenLock(_petsTokenAddress){
        name = "Angel";
        maxCap = 1000000 ether;
        numberLockedMonths = 5; 
        numberUnlockingMonths = 10;
        unlockPerMonth = 100000 ether;
    }

}