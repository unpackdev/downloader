// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ITheCoachFunds.sol";
import "./Address.sol";

contract TheCoachPreminter {
    using Address for address payable;
    ITheCoachFunds private coachContract;

    constructor(address _coachContract) {
        coachContract = ITheCoachFunds(_coachContract);
    }

    function batchPreMintFor(address[] memory addrs, uint256[] memory counts)
        external
        payable
    {
        require(addrs.length == counts.length, "Wrong length");
        uint256 unitPrice = coachContract.getWeiPrice();
        uint256 valueUsed = 0;
        for (uint256 i = 0; i < addrs.length; i++) {
            uint256 totalPrice = unitPrice * counts[i];
            coachContract.preMintFor{value: totalPrice}(addrs[i], counts[i]);
            valueUsed += totalPrice;
        }
        if (msg.value > valueUsed) {
            payable(msg.sender).sendValue(msg.value - valueUsed);
        }
    }
}
