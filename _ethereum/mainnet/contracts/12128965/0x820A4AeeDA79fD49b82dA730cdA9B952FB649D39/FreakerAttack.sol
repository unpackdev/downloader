pragma solidity ^0.8.2;

import "./EtherFreakers.sol";
import "./FreakerFortress.sol";

contract FreakerAttack {
	address payable public owner;
	address public etherFreakersAddress;

	constructor(address payable creator, address _etherFreakersAddress) {
		owner = creator;
		etherFreakersAddress = _etherFreakersAddress;

	}

	function attack(address payable onBehalfOf, uint128 sourceId, uint128 targetId) external returns (bool) {
		require(msg.sender == owner, "FreakerAttack: Only owner");
		require(address(this) == EtherFreakers(etherFreakersAddress).ownerOf(sourceId), "FreakerAttack: does not own sourceId");
		bool success = EtherFreakers(etherFreakersAddress).attack(sourceId, targetId);
		if(success){
			EtherFreakers(etherFreakersAddress).approve(owner, targetId);
			FreakerFortress(owner).depositFreakerFree(onBehalfOf, targetId);
			return true;
		}
		return false;
	}

	// for gas fees, can use a max of four attackers
	// so we only allow for to be sent back 
	function sendBack(uint128[] calldata freakers) external {
		for(uint i=0; i < freakers.length; i++){
			EtherFreakers(etherFreakersAddress).transferFrom(address(this), owner, freakers[i]);
		}
	}
}