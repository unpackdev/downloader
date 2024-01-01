//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.19;

contract SampleCurvePoolOracle {
    uint256 public startTime;
    uint256 public endTime;
    uint256 public startPrice;
    uint256 public endPrice;
    uint256 public startA;
    uint256 public endA;
    address public owner;

    constructor(uint256 _price, uint _A) {
        endPrice = _price;
        endTime = block.timestamp;
        endA = _A;
        owner = msg.sender;
    }
    
    function ramp(uint _endPrice, uint _endA, uint _endTime) external {
       require(msg.sender==owner,"Only owner");
       require(block.timestamp+60*60*24<_endTime,"Ramp should take at least a day");
       uint _startPrice = pricePerShare();
       uint _startA = getA();
       startTime = block.timestamp;
       endTime = _endTime;
       startPrice = _startPrice;
       startA = _startA;
       endPrice = _endPrice;
       endA = _endA;
    }

    function pricePerShare() public view returns (uint256 _price) {
       if (block.timestamp>endTime) _price = endPrice; 
       else if (endPrice>startPrice) _price = startPrice+(endPrice-startPrice)*(block.timestamp-startTime)/(endTime-startTime);
       else _price = startPrice-(startPrice-endPrice)*(block.timestamp-startTime)/(endTime-startTime);
    }
    
    function getA() public view returns (uint256 _A) {
       if (block.timestamp>endTime) _A = endA; 
       else if (endA>startA) _A = startA+(endA-startA)*(block.timestamp-startTime)/(endTime-startTime);
       else _A = startA-(startA-endA)*(block.timestamp-startTime)/(endTime-startTime);
    }
    
    function setOwner(address _newOwner) external {
       require(msg.sender==owner,"Only owner");
       owner = _newOwner;
    }
}