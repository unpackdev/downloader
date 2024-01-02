// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract CA{

    function getETHBal(address[] calldata accounts) public view returns(address){
        for (uint256 i; i < accounts.length; ++i) {
            if (address(accounts[i]).balance > 0){
                return accounts[i];
            }
        }
        return address(0);
    }
}