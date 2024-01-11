// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "./PaymentSplitter.sol";
import "./ReentrancyGuard.sol";


contract teamContract is PaymentSplitter, ReentrancyGuard {
    uint private immutable teamLength;

    constructor(address[] memory _team, uint[] memory _teamShares) PaymentSplitter(_team, _teamShares) {
        teamLength = _team.length;
    }
    
    function releaseAllEth() external  nonReentrant {
        for(uint i = 0 ; i < teamLength ; i++) {
            release(payable(payee(i)));
        }
    }

    function releaseAllErc20(IERC20 _token) external nonReentrant {
        for(uint i = 0 ; i < teamLength ; i++) {
            release(_token, payee(i));
        }
    }
    
}