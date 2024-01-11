// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "BeerCoinOrigContract.sol";


contract BeerCoinHolder {

    BeerCoinOrigContract bcContract = BeerCoinOrigContract(0x74C1E4b8caE59269ec1D85D3D4F324396048F4ac);
    
    constructor(address wrapAddr, uint256 numBeers) {
        bcContract.setMaximumCredit(numBeers);
        bcContract.approve(wrapAddr, numBeers);
    }
}
