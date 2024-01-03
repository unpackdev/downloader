// SPDX-License-Identifier: reeeeeeeeeeee
pragma solidity ^0.6.0;

contract TENSFeeApproverPermanent {
    address public tokenETHPair;
    constructor() public {
            tokenETHPair = 0xB1b537B7272BA1EDa0086e2f480AdCA72c0B511C;
    }

    function calculateAmountsAfterFee(
        address sender,
        address recipient,
        uint256 amount
        ) public  returns (uint256 transferToAmount, uint256 transferToFeeDistributorAmount, uint256 burnAmt)
        {

            // Will block all buys and liquidity removals
            if(sender == tokenETHPair || recipient == tokenETHPair) {
                // This is how a legend dies
                require(false, "TENS is depricated.");
            }

            // No fees 
            // school is out
            transferToAmount = amount;
        
        }


}