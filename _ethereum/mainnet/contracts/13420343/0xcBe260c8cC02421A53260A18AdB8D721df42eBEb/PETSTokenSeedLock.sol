// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./PETSTokenLock2Rates.sol";

contract PETSTokenSeedLock is PETSTokenLock2Rates {

    constructor(address _petsTokenAddress) PETSTokenLock2Rates(_petsTokenAddress){
        name = "Seed";
        maxCap = 3000000 ether;
        numberLockedMonths = 3; 
        numberUnlockingMonths1 = 1;
        unlockPerMonth1 = 300000 ether;
        numberUnlockingMonths2 = 10;
        unlockPerMonth2 = 270000 ether;
    }

}