//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./PaymentSplitter.sol";
import "./Ownable.sol";

contract AVPaymentSplitter is PaymentSplitter, Ownable {
    uint256 private teamLength;

    constructor(address[] memory _team, uint256[] memory _teamShares)
        PaymentSplitter(_team, _teamShares)
    {
        teamLength = _team.length;
    }

    function releaseAll() external onlyOwner {
        for (uint256 i = 0; i < teamLength; i++) {
            release(payable(payee(i)));
        }
    }
}
