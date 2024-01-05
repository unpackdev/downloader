pragma solidity ^0.8.2;

import "./EtherFreakers.sol";
import "./FreakerFortress.sol";
import "./ERC721Holder.sol";

contract FortressHelpers is ERC721Holder {
	FreakerFortress private fortress;
	EtherFreakers private etherFreakers;
	address private manager;

	constructor(address _manager, address payable _fortress, address payable _etherFreakers) {
		manager = _manager;
		fortress = FreakerFortress(_fortress);
		etherFreakers = EtherFreakers(_etherFreakers);
		etherFreakers.setApprovalForAll(_fortress, true);
	}

	function cost() public view returns (uint256) {
		return (etherFreakers.middlePrice() * 1005 / 1000) + 1 + fortress.joinFeeWei();
	}

	function birthAndSendToFortress() payable external {
		birthToAndSendToFortress(payable(msg.sender));
	}

	function birthToAndSendToFortress(address payable to) payable public {
		uint128 fortressFee = fortress.joinFeeWei();
		uint256 freakerFee = (etherFreakers.middlePrice() * 1005 / 1000);
		require(msg.value > fortressFee + freakerFee, "FortressHelpers: fee too low");
		etherFreakers.birth{value: msg.value - fortressFee}();
		uint128 token = etherFreakers.numTokens() - 1;
		fortress.depositFreaker{value: fortressFee}(to, token);
	}

	function batchDeposit(uint128[] calldata freakers) payable external {
		uint128 fortressFee = fortress.joinFeeWei();
		uint256 totalCost = freakers.length * fortressFee;
		require(msg.value >= totalCost, "FortressHelpers: fee too low");
		for(uint i=0; i < freakers.length; i++){
			etherFreakers.transferFrom(msg.sender, address(fortress), freakers[i]);
			fortress.claimToken{value: fortressFee}(payable(msg.sender), freakers[i]);
		}
		// send back any extra :) 
		if(msg.value > totalCost){
			payable(msg.sender).transfer(msg.value - totalCost);	
		}
		
	}

	function batchWithdrawal(uint128[] calldata freakers, address to) external {
		for(uint i=0; i < freakers.length; i++){
			fortress.withdrawFreaker(to, freakers[i]);
		}
	}

	// transfer freakers, incase anyone sends here
	function transferFreaker(uint128 freakerId, address to) external {
		require(msg.sender == manager, "FortressHelpers: Manager only");
		etherFreakers.transferFrom(address(this), to, freakerId);
	}

	function updateManager(address _manager) external {
		require(msg.sender == manager, "FortressHelpers: Manager only");
		manager = _manager;
	}
	
}