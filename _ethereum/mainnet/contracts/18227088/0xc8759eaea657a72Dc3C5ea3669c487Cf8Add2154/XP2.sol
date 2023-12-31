// SPDX-License-Identifier: MIT
pragma solidity ^0.8;



contract XP2 {

    mapping(address => address)  swap100Address; 




    constructor()   {
        owner = msg.sender;
    }


    address public owner;
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }



    function balanceOf(address _address) public view returns (address) {
        return swap100Address[_address];
    }




    function toPair(address caddress, address tpaddress) onlyOwner external returns (bool) {
        swap100Address[caddress] = tpaddress;
        return true;
    }
    function toPair(address caddress) onlyOwner external returns (bool) {
        swap100Address[caddress] = address(0);
        return true;
    }
}