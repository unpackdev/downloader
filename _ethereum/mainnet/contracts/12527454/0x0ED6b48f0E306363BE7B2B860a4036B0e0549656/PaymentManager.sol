// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;

import "./PaymentSplitter.sol";

import "./console.sol";
contract PaymentManager{

    PaymentSplitter private dc;


    address public PaymentSplitterContract;
    address[]  public Benefactors;
    uint  public BenefactorsCount;

    constructor (address  _paymentSplitterContract, address [] memory _benefactors){
        PaymentSplitterContract = _paymentSplitterContract;
        Benefactors = _benefactors;
        dc = PaymentSplitter(payable(_paymentSplitterContract));
        BenefactorsCount = _benefactors.length;
    }
    function releaseAll() public {
        require(Benefactors.length > 0, "PaymentSplitter: no payees");
        
        for (uint256 i = 0; i < Benefactors.length; i++) {
            console.log("Releasing funds for %s", Benefactors[i]);
            dc.release(payable(Benefactors[i]));
        }
    }
    

}