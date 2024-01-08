

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./SafeMath.sol";
import "./Ownable.sol";


interface IBase {
	function balanceOf(address _user) external view returns(uint256);
}

contract YieldToken is Ownable, ERC20("Noise", "NOISE") {
	using SafeMath for uint256;

	uint256 public BASE_RATE = 3 ether; 
	uint256 public START = block.timestamp;
    uint256 public MAX = 600000 ether;
    
    uint256 public total = 0 ether;

	mapping(address => uint256) public lastUpdate;
	mapping(address => uint256) public lastBalance;
	
	mapping(address => bool) public initialLiquidClaimed;


	IBase public signals;


	constructor(address _signals) {
    	signals = IBase(_signals);
	}

	function max(uint256 a, uint256 b) internal pure returns (uint256) {
		return a > b ? a : b;
	}
	
	
	function min(uint256 a, uint256 b) internal pure returns (uint256) {
		return a < b ? a : b;
	}

	function getReward(address _user) public {
	    require(total < MAX, "no more mints!");
	    require(signals.balanceOf(_user) > 0, "No signals!");
	    uint256 pending =  getTotalClaimable(_user);

        
		if (pending > 0) {
		    if (total + pending > MAX) {
		        uint256 remaining = MAX - total;
		        super._mint(_user, remaining);
		        total += remaining;
		    } else {
    		    total += pending;
    			super._mint(_user, pending);
		    }
		}
		lastUpdate[_user] = block.timestamp;
		lastBalance[_user] = signals.balanceOf(_user);
	}

	function getTotalClaimable(address _user) public view returns(uint256) {
		uint256 time = block.timestamp;
		uint256 start = max(START, lastUpdate[_user]);
		uint256 pending;
        if (lastBalance[_user] == 0) {
            pending = signals.balanceOf(_user).mul(BASE_RATE.mul((time.sub(start)))).div(86400);
        } else {
            pending = min(lastBalance[_user], signals.balanceOf(_user)).mul(BASE_RATE.mul((time.sub(start)))).div(86400);
        }
        
        return pending;
	}
	
	function setBaseRate(uint256 base) public onlyOwner {
	    BASE_RATE = base;
	}
	
	function setMaxTokens(uint256 max) public onlyOwner {
	    MAX = max;
	}
}