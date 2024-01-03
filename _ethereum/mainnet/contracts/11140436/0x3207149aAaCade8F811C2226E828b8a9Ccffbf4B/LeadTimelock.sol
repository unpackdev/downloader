//"SPDX-License-Identifier: UNLICENSED"
pragma solidity ^0.6.6;

interface IERC20 {
    function transfer(address to, uint tokens) external returns (bool success);
    function transferFrom(address from, address to, uint tokens) external returns (bool success);
    function balanceOf(address tokenOwner) external view returns (uint balance);
    function approve(address spender, uint tokens) external returns (bool success);
    function allowance(address tokenOwner, address spender) external view returns (uint remaining);
    function totalSupply() external view returns (uint);
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }

    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }

    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }

    function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}

contract LeadTimelock {
    using SafeMath for uint;

    uint8 private nextSubtract = 0;
    uint8 private nextScheduleId = 0;
    address public lead;
    address[] private beneficiaries; 
    uint[] private scheduleList; 

    mapping(uint8 => uint) private schedules;
    mapping(address => uint) private percentages;        
    mapping(address => uint) private proportions;
    
    event Distributed(address executor, uint indexed round);
    
    constructor(address token, address[] memory _beneficiary, uint[] memory _percentages, uint[] memory _schedules) public {
        lead = token;
        _addVesting(_beneficiary, _percentages, _schedules);
    }
    
    function _addVesting(address[] memory _beneficiary, uint[] memory _percentages, uint[] memory _schedules) private {
        require(_beneficiary.length == _percentages.length, 'Beneficiary and percentage arrays must have the same length');
        uint totalPercentages;
        for(uint i = 0; i < _beneficiary.length; i++) {
            beneficiaries.push(_beneficiary[i]);
            percentages[_beneficiary[i]] = _percentages[i];
            totalPercentages = totalPercentages.add(_percentages[i]);
        }
        require(totalPercentages == 100, 'Percentages must sum up to 100');
        for(uint8 i = 0; i < _schedules.length; i++) {
            scheduleList.push(_schedules[i]);
            schedules[i] = now + _schedules[i];
        }
    }
    
    function getSchedules() external view returns(uint[] memory schedule){
        return scheduleList;
    }
    
    function currentSchedule() external view returns(uint schedule){
        return scheduleList[nextScheduleId];
    }
    
    function getPercentage(address _beneficiary) external view returns(uint percent){
        return percentages[_beneficiary];
    }
    
    function getBeneficiaries() external view returns(address[] memory beneficiary) {
        return beneficiaries;
    }
    
    function nextScheduleTime() external view returns(uint secondsLeft){
        uint time = schedules[nextScheduleId];
        uint nextTime = time - now;
        if (time < now) {
            revert ('distribute payment for previous round(s)');
        } else {
            return nextTime;
        }
    }
    
    function endingTime() external view returns(uint secondsLeft){
        uint allTime = scheduleList.length;
        uint time = schedules[uint8(allTime) - 1];
        require(time > now, 'Contract has been completed');
        return time - now;
    }
    
    function _calculatePayment(address _beneficiary) private view returns(uint){
        uint balance = IERC20(lead).balanceOf(address(this));
        require(balance > 0, 'Empty pool');
        return (percentages[_beneficiary] * balance) / ((scheduleList.length - nextSubtract) * (100));
    }

    function distributePayment() external {
        require(now >= schedules[nextScheduleId], 'Realease time not reached');
        for (uint i = 0; i < beneficiaries.length; i++) {
            proportions[beneficiaries[i]] = proportions[beneficiaries[i]].add(_calculatePayment(beneficiaries[i]));
        }
        for (uint i = 0; i < beneficiaries.length; i++) {
            IERC20(lead).transfer(beneficiaries[i], proportions[beneficiaries[i]]);
            proportions[beneficiaries[i]] = 0;
        }
        nextScheduleId++; 
        nextSubtract++;
        emit Distributed(msg.sender, nextScheduleId);
    }
}