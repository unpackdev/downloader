/**
* @author NiceArti (https://github.com/NiceArti) 
* To maintain developer you can also donate to this address - 0xDc3d3fA1aEbd13fF247E5F5D84A08A495b3215FB
* @title The interface for implementing the CryptoFlatsNft smart contract 
* with a full description of each function and their implementation 
* is presented to your attention.
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface ICflatsDapp
{
    enum PaymentPlan {NO_PLAN, CHEAP, MEDIUM, BEST}
    enum FraudStatus {UNSUCCESFULL, SUCCESSFUL}
    enum DappStrategy {ATTACK, RETURN}

    struct TaxMultiplier
    {
        uint8 _multplier;
        uint256 _timer;
    }

    struct VictimReturn
    {
        uint256 _stolenAmount;
        uint256 _timer;
    }

    event SuccessfulFraud(address indexed fraudster, address indexed victim, uint256 stolenAmount);
    event UnsucessfulFraud(address indexed fraudster);

    event SuccessfulPunish(address indexed victim, address indexed fraudster, uint256 returnAmount);
    event UnsucessfulPunish(address indexed victim, address indexed fraudster);
}