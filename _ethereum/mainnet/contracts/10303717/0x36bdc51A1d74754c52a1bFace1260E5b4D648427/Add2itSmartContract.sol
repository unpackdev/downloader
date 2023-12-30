/*
Add2itSmartContract:  Distribute funds to multiple addresses in a single call

Used by sites owned and operated by:

Add2it.com Marketing Pty Ltd
P.O. Box 290
Stanhope Gardens NSW 2768
Australia

For support, please visit:  https://Reply2Frank.com
*/

pragma solidity  ^0.6.3;

contract Add2itSmartContract {
    function multisend(uint256[] memory amounts, address payable[] memory receivers) payable public {
        assert(amounts.length == receivers.length);
        assert(receivers.length <= 100);
        for (uint i = 0; i < receivers.length; i++) {
            receivers[i].transfer(amounts[i]);
        }
    }
}