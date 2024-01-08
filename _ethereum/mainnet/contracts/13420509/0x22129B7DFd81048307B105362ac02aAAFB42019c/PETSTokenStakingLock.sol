// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./PETSTokenLock.sol";

contract PETSTokenStakingLock is PETSTokenLock {

    constructor(address _petsTokenAddress) PETSTokenLock(_petsTokenAddress){
        name = "Staking";
        maxCap = 11400000 ether;
        numberLockedMonths = 0; 
        numberUnlockingMonths = 19;
        unlockPerMonth = 600000 ether;
    }

}