//SPDX-License-Identifier: MIT

/*

 ____                     __               __          ______    __              ______           __                
/\  _`\                  /\ \__         __/\ \        /\__  _\__/\ \      __    /\__  _\       __/\ \               
\ \ \L\ \     __     __  \ \ ,_\   ___ /\_\ \ \/'\    \/_/\ \/\_\ \ \/'\ /\_\   \/_/\ \/ _ __ /\_\ \ \____     __   
 \ \  _ <'  /'__`\ /'__`\ \ \ \/ /' _ `\/\ \ \ , <       \ \ \/\ \ \ , < \/\ \     \ \ \/\`'__\/\ \ \ '__`\  /'__`\ 
  \ \ \L\ \/\  __//\ \L\.\_\ \ \_/\ \/\ \ \ \ \ \\`\      \ \ \ \ \ \ \\`\\ \ \     \ \ \ \ \/ \ \ \ \ \L\ \/\  __/ 
   \ \____/\ \____\ \__/.\_\\ \__\ \_\ \_\ \_\ \_\ \_\     \ \_\ \_\ \_\ \_\ \_\     \ \_\ \_\  \ \_\ \_,__/\ \____\
    \/___/  \/____/\/__/\/_/ \/__/\/_/\/_/\/_/\/_/\/_/      \/_/\/_/\/_/\/_/\/_/      \/_/\/_/   \/_/\/___/  \/____/
                                                                                                                                                                                                                                        
*/

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./Counters.sol";


contract TikiReservation is Ownable {

    using Counters for Counters.Counter;

    event TikiReserved(address _address);
    
    mapping (address => bool) public allowedToSend;
    mapping (address => uint256) public reservedTikis;

    uint256 public reservationFee;
    uint256 public maxReservedTikis;

    Counters.Counter private _totalReservations;
    Counters.Counter private _totalAddresses;

    constructor () {
        reservationFee = 0.08 ether;
        maxReservedTikis = 1;
    }
    
    function addAddress(address _address) public onlyOwner {
        require(_address != address(0), "Cannot add null address");
        require(!allowedToSend[_address], "Address already in whitelist");
        
        allowedToSend[_address] = true;
        _totalAddresses.increment();  
    }

    function removeAddress(address _address) public onlyOwner {
        require(_address != address(0), "Cannot remove null address");
        require(allowedToSend[_address], "Address not in whitelist");
        
        allowedToSend[_address] = false;
        _totalAddresses.decrement();
    }

    function bulkaddAddresses(address[] calldata _addresses) public onlyOwner {
        for (uint i=0; i<_addresses.length; i++) {
            
            address _address = _addresses[i];
            
            if (!allowedToSend[_address] && _address != address(0)) {
                allowedToSend[_address] = true;
                _totalAddresses.increment();
            }

        }
            
    }

    function setReservationFee(uint256 _fee) public onlyOwner {
        reservationFee = _fee;
    }

    function setMaxReservedTikis(uint256 _tikis) public onlyOwner {
        maxReservedTikis = _tikis;
    }

    function getTotalReservations() public view onlyOwner returns (uint256) {
        return _totalReservations.current();
    }

    function getTotalAddresses() public view onlyOwner returns (uint256) {
        return _totalAddresses.current();
    }

    function isAddressAllowed(address _address) public view returns (bool) {
        return allowedToSend[_address];
    }

    function getTikisReservedBy(address _address) public view returns (uint256) {
        return reservedTikis[_address];
    }

    function getAddressStatus(address _address) public view returns (bool, uint256) {
        return (allowedToSend[_address], reservedTikis[_address]);
    }

    function getBalance() public view onlyOwner returns (uint256) {
        return address(this).balance;
    }

    function withdraw() public onlyOwner {
        uint256 _balance = address(this).balance;
        address payable _sender = payable(_msgSender());
        _sender.transfer(_balance);
    }

    
    function reserveTiki() public payable {

        address _sender = _msgSender();
        require(allowedToSend[_sender], "Sender is not in allowed list");
        require(reservedTikis[_sender] < maxReservedTikis, "Cannot reserve any more tikis");
        require(msg.value >= reservationFee, "Insufficient funds to reserve tiki");

        address payable _payableSender = payable(_sender);
        _payableSender.transfer(msg.value - reservationFee);

        reservedTikis[_sender] += 1;
        _totalReservations.increment();

        emit TikiReserved(_sender);
    }
}