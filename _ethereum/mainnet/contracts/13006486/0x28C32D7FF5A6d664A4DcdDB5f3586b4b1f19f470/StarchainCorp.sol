pragma solidity ^0.8.0;

import "./PaymentSplitter.sol";

contract StarchainCorp is PaymentSplitter {
    
    address[] _payees = [
        0x551E0713059896774721025e9953FCBE073AB4cE, // amon-ra
        0x221728354433C8329481c9CB413fBAE7A0F6C6d3, // cybersage
        0x3258E64Cf0C51BA9099472c2ADc8D83Fa13831D9 // lazerhawk5000
    ];
    uint256[] _shares = [100, 100, 100];
    
    constructor() PaymentSplitter(_payees, _shares) {
    }
    
    function payDividends() public {
        for (uint i=0; i < _payees.length; i++) {
            release(payable(_payees[i]));
        }
    }
}