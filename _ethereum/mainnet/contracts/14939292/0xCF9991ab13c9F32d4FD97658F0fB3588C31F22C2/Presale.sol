// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./Ownable.sol";
import "./Counters.sol";

contract Presale is Ownable{
    using Counters for Counters.Counter;
    Counters.Counter private _prepayCounter;

    event Preordered(address indexed to, uint256 payerId);  

    uint256 public constant MAX_PREPAID = 800;
    uint256 public prepaymentCost = 200000000000000000;
    uint256 constant paymentToCreator = 10;
    uint256 public paidToCreator;
    uint256 constant maxToCreator = 35 ether;
    
    bool public creatorPaidOff = false;
    bool public paused = false;

    address payable private _creator;
    address[] public prepaidUsers;

    mapping (address => bool) private preorder;

    constructor(address payable creator){
        _creator = creator;
    }


    modifier whenNotPaused(){
        require(paused == false, "Contract Paused");
        _;
    }

    function prePay() public payable whenNotPaused {
        require(msg.value >= prepaymentCost, "Insufficient payment");
        require(_prepayCounter.current() <= MAX_PREPAID - 1, "Max reached");
        require(!preorder[msg.sender], "Max preorder is 1");
        if(creatorPaidOff == false){
            uint256 creatorPaymentAmount = msg.value * (paymentToCreator);
            if(paidToCreator + (creatorPaymentAmount/100) <= maxToCreator) {
                paidToCreator += (creatorPaymentAmount/100);
                _creator.transfer((creatorPaymentAmount/100));
            } else {
                uint256 amtLeftToPay = maxToCreator - paidToCreator;
                paidToCreator += amtLeftToPay;
                creatorPaidOff = true;
                _creator.transfer(amtLeftToPay);
            }
        }

        prepaidUsers.push(msg.sender);
        preorder[msg.sender] = true;
        _prepayCounter.increment();

        emit Preordered(msg.sender, _prepayCounter.current());
    }

    function setPaused(bool _state) public onlyOwner {
        paused = _state;
    }

    function setPrepayCost(uint256 cost) public onlyOwner {
        prepaymentCost = cost;
    }

    function totalPrepaid() public view returns (uint256) {
        return _prepayCounter.current();
    }

    function getBalance() public view returns (uint256){
        return address(this).balance;
    }

    function isPreordered(address account) public view returns (bool){
        return preorder[account];
    }

    function withdraw() public onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function getAllPrepaid() public view returns (address[] memory){
        address[] memory orderAddresses = new address[](prepaidUsers.length);
        
        for (uint256 i = 0; i < prepaidUsers.length; i++){
            orderAddresses[i] = prepaidUsers[i];
        }
        return orderAddresses;
    }

    function getCreatorPayment() public view returns (uint256){
        uint256 amtLeftToPay = maxToCreator - paidToCreator;
        return amtLeftToPay;
    }
}