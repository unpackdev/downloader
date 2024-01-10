// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./GenerativeBB.sol";

contract NonGenerativeBB is GenerativeBB {
 using Counters for Counters.Counter;
    using SafeMath for uint256;
  
   

    function updateBoxStartTimeNonGen(uint256 seriesId, uint256 startTime) onlyOwner public {
        nonGenSeries[seriesId].startTime = startTime;
    }

    function updateNonGenUserPerBoxLimit(uint256 seriesId, uint256 limit) onlyOwner public {
        _perBoxUserLimit[seriesId] = limit;
    }
    
   
}