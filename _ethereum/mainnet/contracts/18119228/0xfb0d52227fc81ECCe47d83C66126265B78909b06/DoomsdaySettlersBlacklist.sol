// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.21;

contract DoomsdaySettlersBlacklist{

    address public owner;
    constructor(){
        owner = msg.sender;
    }

    mapping(address => bool) blocked;

    function checkBlocked(address _addr) external view returns(bool){
        return blocked[_addr];
    }

    function blockAddress(address _addr,bool _enable) public{
        require(msg.sender == owner,"owner");
        blocked[_addr] = _enable;
    }

    function blockAddresses(address[] calldata _addrs,bool _enable) public{
        require(msg.sender == owner,"owner");
        for(uint i = 0; i < _addrs.length; i++){
            blocked[_addrs[i]] = _enable;
        }
    }
}