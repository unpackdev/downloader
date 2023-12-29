/**
 *Submitted for verification at Etherscan.io on 2020-04-06
*/

pragma solidity ^0.5.12;

contract tokenInterface {
	function balanceOf(address _owner) public view returns (uint256 balance);
	function transfer(address _to, uint256 _value) public returns (bool);
}

contract LocktimeAgreementTCJ {

    tokenInterface public tcj;
    uint256 public totAmount ;
    uint8 public deadlines;
    uint256 public deadlinesTime;
	uint256 public dataUnlock;
	address payable public addrFrom;
	address payable public addrTo;
	bool public signed;
	uint public currentDeadline;

	constructor( address _tcj, uint256 _tcjTotAmount, uint8 _deadlines, uint256 _deadlinesTimeDD, uint256 _dataUnlock, address payable _addrFrom, address payable _addrTo) public {
		
		require( _tcjTotAmount > 0, " totAmount > 0");
		require( _deadlines > 0, " deadlines > 0");
		
		tcj = tokenInterface(_tcj);
		totAmount = _tcjTotAmount * 1e18;
		deadlines = _deadlines;
		deadlinesTime = _deadlinesTimeDD * 24 * 60 * 60;
		dataUnlock = _dataUnlock;
		addrFrom = _addrFrom;
		addrTo = _addrTo;
	}

	function enabled() public view returns(bool) {
	    bool paid = tcj.balanceOf(address(this)) >= 0;
	    if(signed && paid)
	        return true;
	    else
	        return false;
	}
	
    function nextDataUnlock() public view returns(uint256) {
	   return dataUnlock + ( currentDeadline * deadlinesTime );
	}
	
	 function singleRate() public view returns(uint256) {
	   return totAmount / deadlines;
	}
	
	function () external {
	    uint256 tcj_amount = tcj.balanceOf(address(this));
	    if(enabled()) {
	        if ( msg.sender == addrTo ) {
	            require(now>nextDataUnlock(),"now > nextDataUnlock");
	            tcj.transfer(addrTo, singleRate());
	            currentDeadline++;
	        } else
	            revert("No auth.");
	    } else {
	        if(msg.sender == addrFrom) {
	            if( tcj_amount > 0)
	                tcj.transfer(addrFrom, tcj_amount);
	        } else if(msg.sender == addrTo) {
	            require(tcj_amount > 0, "tcj_amount > 0");
	            signed = true;
	        }else
	            revert("No auth.");
	    }
	}
}