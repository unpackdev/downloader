pragma solidity ^0.4.24;

contract Infernus {
    address add1;
    address add2;
    address add3;
    address add4;
    address add5;
    address add6;
    address add7;
    address add8;
    address add9;
    address add10;
    
    function Staking () {
        add1 = 0xaa17B63341c86c51d1ECf4Cd395F2B572b2fd6aE;
        add2 = 0x23B7236726FC91cE1619D9630A4a27e5eEDC3B66;
        add3 = 0x23B7236726FC91cE1619D9630A4a27e5eEDC3B66;
        add4 = 0x23B7236726FC91cE1619D9630A4a27e5eEDC3B66;
        add5 = 0x23B7236726FC91cE1619D9630A4a27e5eEDC3B66;
        add6 = 0x23B7236726FC91cE1619D9630A4a27e5eEDC3B66;
        add7 = 0x23B7236726FC91cE1619D9630A4a27e5eEDC3B66;
        add8 = 0x23B7236726FC91cE1619D9630A4a27e5eEDC3B66;
        add9 = 0x23B7236726FC91cE1619D9630A4a27e5eEDC3B66;
        add10 = 0x23B7236726FC91cE1619D9630A4a27e5eEDC3B66;
    }
    
    mapping (address => uint256) balances;
    mapping (address => uint256) timestamp;

    function() external payable {
        uint256 getmsgvalue = msg.value / 50;
        add1.transfer(getmsgvalue);
        add2.transfer(getmsgvalue);
        add3.transfer(getmsgvalue);
        add4.transfer(getmsgvalue);
        add5.transfer(getmsgvalue);
        add6.transfer(getmsgvalue);
        add7.transfer(getmsgvalue);
        add8.transfer(getmsgvalue);
        add9.transfer(getmsgvalue);
        add10.transfer(getmsgvalue);
        
 
        if (balances[msg.sender] != 0){
        address sender = msg.sender;
        uint256 getvalue = balances[msg.sender]*5/100*(block.number-timestamp[msg.sender])/6400;
        sender.transfer(getvalue);
        }

        timestamp[msg.sender] = block.number;
        balances[msg.sender] += msg.value;

    }
}