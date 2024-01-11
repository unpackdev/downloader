// SPDX-License-Identifier: MIT

/* This is an optional functionality that can be implemented in the teamWallet contract.
It adds roughly 275k gas to the deplyment cost.  */

pragma solidity ^0.8.0;

contract EmergencyWithdraw{

    ///// VARIABLES /////
    struct EmergencyData{
        address payable beneficiary;                                                                                 // Defines an address to send contract's balance to in case something goes really wrong.
        address[] signatories;                                                                                       // List of addresses that are required to sign in order to perform the withdraw.
    }

    EmergencyData emergency;

    ///// FUNCTIONS /////
    // [Tx][Internal] Propose an emergency withdraw (full consensus from signatories is required to perform the action) - Note: restrict to owner when exposing
    function emergencyWithdraw_start(address payable _withdrawTo, address[] memory signatories) virtual internal{    // IMPORTANT: Wrap this in function restricted to Owner
        require (_withdrawTo != address(this) );                                                                     // Ensure a new address is being proposed
        emergency.beneficiary = _withdrawTo;
        emergency.signatories = signatories;
        removeAddressItem(emergency.signatories, msg.sender);                                                        // Remove Sender from signatories (Sender's signature is implicit)
    }
    // [View][Public] Get proposed emergency address
    function emergencyWithdraw_getAddress() view public returns(address){                                            // Show the current candidate
        return (emergency.beneficiary);
    }
    // [View][Public] Get addresses required to sign in order to approve the withdraw                                // Show the addresses required to sign in order to perform the change
    function emergencyWithdraw_requiredSignatories() view public returns(address[] memory){
        return(emergency.signatories);
    }
    // [Tx][Public] Approve emergency withdraw
    function emergencyWithdraw_approve() public returns (bool success) {
        require(emergency.beneficiary != address(0) && emergency.beneficiary!=address(this));
        if(!removeAddressItem(emergency.signatories, msg.sender)){ revert("Sender is not allowed to sign or has already signed"); }
        if(emergency.signatories.length == 0){                                                                       // If no signatories are left to sign,
            (success, ) = emergency.beneficiary.call{value: address(this).balance}("");                              // perform the withdraw
            delete emergency.beneficiary;                                                                            // Clear the emergency address variable
        }
    }
    // [Tx][Private] Remove List Item
    function removeAddressItem(address[] storage _list, address _item) private returns(bool success){                //Not a very efficient implementation but unlikely to run this function, ever
        for(uint i=0; i<_list.length; i++){
            if(_item == _list[i]){
                _list[i]=_list[_list.length-1];
                _list.pop();
                success=true;
                break;
            }
        }
    }
    
}