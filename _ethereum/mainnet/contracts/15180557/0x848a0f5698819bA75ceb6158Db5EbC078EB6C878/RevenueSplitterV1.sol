// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/*
                          G#BBBBBBBBBBBBBBBBBB#P    P#BBBBBBBBBBBBBBBBBB#G                          
                          @@@@@@@@@@@@@@@@@@@@@&    &@@@@@@@@@@@@@@@@@@@@@                          
                          &@@@@@@@@@@@@@@@@@@@@&    &@@@@@@@@@@@@@@@@@@@@&                          
                          &@@@@@@@@@@@@@@@@@@@@&    &@@@@@@@@@@@@@@@@@@@@&                          
                          &@@@@@@@@@@@@@@@@@@@@&    &@@@@@@@@@@@@@@@@@@@@&                          
                          &@@@@@@@@@@@@@@@@@@@@&    &@@@@@@@@@@@@@@@@@@@@&                          
                          &@@@@@@@@@@@@@@@@@@@@&    &@@@@@@@@@@@@@@@@@@@@&                          
                          &@@@@@@@@@@@@@@@@@@@@&    &@@@@@@@@@@@@@@@@@@@@&                          
                          &@@@@@@@@@@@@@@@@@@@@&    &@@@@@@@@@@@@@@@@@@@@&                          
                          &@@@@@@@@@@@@@@@@@@@@&    &@@@@@@@@@@@@@@@@@@@@&                          
             ?YYYYYYYYYYYY@@@@@@@@&JJJJ@@@@@@@@@YYYY@@@@@@@@@JJJJ&@@@@@@@@Y?!^.                     
             @@@@@@@@@@@@@@@@@@@@@#    &@@@@@@@@@@@@@@@@@@@@&    #@@@@@@@@@@@@@&5^                  
             &@@@@@@@@@@@@@@@@@@@@#    &@@@@@@@@@@@@@@@@@@@@&    #@@@@@@@@@@@@@@@@&~                
             &@@@@@@@@@@@@@@@@@@@@#    &@@@@@@@@@@@@@@@@@@@@&    #@@@@@@@@@@@@@@@@@@B               
             &@@@@@@@@@@@@@@@@@@@@#    &@@@@@@@@@@@@@@@@@@@@&    #@@@@@@@@@@@@@@@@@@@&              
             &@@@@@@@@@@@@@@@@@@@@#    &@@@@@@@@@@@@@@@@@@@@&    #@@@@@@@@@@@@@@@@@@@@5             
             &@@@@@@@@@@@@@@@@@@@@#    &@@@@@@@@@@@@@@@@@@@@&    #@@@@@@@@@@@@@@@@@@@@&             
             G@@@@@@@@@@@@@@@@@@@@#    &@@@@@@@@@@@@@@@@@@@@&    #@@@@@@@@@@@@@@@@@@@@&             
             .@@@@@@@@@@@@@@@@@@@@#    B@@@@@@@@@@@@@@@@@@@@B    #@@@@@@@@@@@@@@@@@@@@&             
              :&@@@@@@@@@@@@@@@@@@#    .@@@@@@@@@@@@@@@@@@@@.    #@@@@@@@@@@@@@@@@@@@@&             
                Y@@@@@@@@@@@@@@@@@#     .#@@@@@@@@@@@@@@@@#.     #@@@@@@@@@@@@@@@@@@@@&             
                  7B@@@@@@@@@@@@@@&       ~B@@@@@@@@@@@@B~       &@@@@@@@@@@@@@@@@@@@@@             
                     :7YGBBBBBBBB#5         .^?PBBBBP?^.         5#BBBBBBBBBBBBBBBBBB#G             
*/

import "./OwnableUpgradeable.sol";
import "./PaymentSplitterUpgradeable.sol";

contract RevenueSplitterV1 is OwnableUpgradeable, PaymentSplitterUpgradeable {
    uint256 private _totalPayees;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address[] memory payees_, uint256[] memory shares_)
        public
        initializer
    {
        __BatchPaymentSplitter_init(payees_, shares_);
    }

    function __BatchPaymentSplitter_init(
        address[] memory payees_,
        uint256[] memory shares_
    ) internal onlyInitializing {
        __Ownable_init_unchained();
        __PaymentSplitter_init_unchained(payees_, shares_);
        __BatchPaymentSplitter_init_unchained(payees_, shares_);
    }

    function __BatchPaymentSplitter_init_unchained(
        address[] memory payees_,
        uint256[] memory shares_
    ) internal onlyInitializing {
        _totalPayees = payees_.length;
    }

    function batchRelease() public onlyOwner {
        for (uint256 i = 0; i < _totalPayees; i++) {
            release(payable(payee(i)));
        }
    }
}
