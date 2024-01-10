// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./Ownable.sol";

interface IETHRegistrarController {
	function available(string memory name) external view returns(bool);
	function register(string calldata name, address owner, uint duration, bytes32 secret) external payable;
	function rentPrice(string memory name, uint duration) external view returns(uint);
	function makeCommitment(string memory name, address owner, bytes32 secret) external pure returns(bytes32);
	function commit(bytes32 commitment) external;
}

contract BulkRegistrar is Ownable {
	address private ETHRegistrarControllerAddress;
	uint public FEE = 0 ether;
	uint public gasAdded = 20000;
	uint256 public perc_gasFee = 5;
	bool public flatFee = false;

	constructor(address _ETHRegistrarControllerAddress) {
		ETHRegistrarControllerAddress = address(_ETHRegistrarControllerAddress);
	}	

	function getController() internal view returns(IETHRegistrarController) {
		return IETHRegistrarController(ETHRegistrarControllerAddress);
	} 

	function available (string memory name) external view returns(bool) {
		IETHRegistrarController controller = getController();	
	 	return controller.available(name);	
	}

	function rentPrice(string[] calldata names, uint duration) external view returns(uint total) {
		IETHRegistrarController controller = getController();
		for(uint i = 0; i < names.length; i++) {
			total += controller.rentPrice(names[i], duration);
		}
	}
		
	function submitCommit(string[] calldata names, address owner, bytes32 secret) external {
		IETHRegistrarController controller = getController();
		for(uint i = 0; i < names.length; i++) {
			bytes32 commitment = controller.makeCommitment(names[i],owner,secret);
			controller.commit(commitment);
		}
	}

	function registerAll(string[] calldata names, address _owner, uint duration, bytes32 secret) external payable {
		require(_owner == msg.sender, "Error: Caller must be the same address as owner");
	
		// Calculate fees
		uint fee;	
		if(!flatFee) {
			uint gas = gasleft() + gasAdded;
			fee = (((gas * perc_gasFee) / 100) * tx.gasprice);
		} else {
			fee = FEE;
		}	
		
		IETHRegistrarController controller = getController();	
		for(uint i = 0; i < names.length; i++) {
			uint cost = controller.rentPrice(names[i], duration);
			controller.register{value:cost}(names[i], _owner, duration, secret);
		}
		// Pay owner fee and Send any excess funds back
		payable(owner()).transfer(fee);
		payable(msg.sender).transfer(address(this).balance);
	}

	// Admin
	function setPercentageGas(uint256 percentage) external onlyOwner {
        perc_gasFee = percentage;
    }
	
	function changeFeeStyle(bool style) external onlyOwner {
		flatFee = style;
	}

	function changeFee(uint _fee) external onlyOwner {
		FEE = _fee;
	}	
}
