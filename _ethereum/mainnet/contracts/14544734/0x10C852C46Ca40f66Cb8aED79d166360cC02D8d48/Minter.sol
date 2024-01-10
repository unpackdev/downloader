// SPDX-License-Identifier: AGPL-3.0-or-later


pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";

interface IBaseCollection {
    function mintFor(address account, bytes memory _signature) external payable;
	function price() external returns(uint256);
}

contract Minter is Ownable, ReentrancyGuard {
	
	function mint(IBaseCollection target, address account, bytes memory _signature, uint256 amount) external nonReentrant payable{
		uint256 price = target.price();
		for(uint i=0;i<amount;){
			target.mintFor{value : price}(account, _signature);
			unchecked{++i;}
		}
	}
	
	function withdraw() external {
		uint256 balance = address(this).balance;
		(bool sent,) = owner().call{value: balance}("");
        require(sent, "Failed to withdraw");
    }

	fallback() external payable {}

    receive() external payable {}
}