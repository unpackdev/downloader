// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import "./Ownable.sol";

error NotAllowed();
error ToMuchToWithdraw();
error ETHTransferFailed();
error NoBalanceToWithdraw();

contract Depositor is Ownable {

    struct TeamMember {
        uint16 percentage;
        uint256 balance;
    }

    // receiver address of the team members
    address[4] public receiverAddresses;
    // details of funds received by team member
    mapping(address => TeamMember) public team;

	constructor(address[4] memory receiverAddresses_, uint8[4] memory receiverPercentages_) {
		receiverAddresses = receiverAddresses_;
		for (uint256 i; i < receiverAddresses_.length; i++) {
			team[receiverAddresses_[i]] = TeamMember(receiverPercentages_[i], 0);
		}
	}

	/*
	 * accepts ether sent with no txData
	 */
	receive() external payable {
		for (uint256 i; i < receiverAddresses.length; i++) {
			address receiverAddress = receiverAddresses[i];
			uint256 maxToWithdraw = (msg.value * team[receiverAddress].percentage) / 100;
			_sendValueTo(receiverAddress, maxToWithdraw);
		}
	}

	/**
	 * @dev Change the current team member address with a new one
	 * @param newAddress Address which can withdraw the ETH based on percentage
	 */
	function changeTeamMemberAddress(address newAddress) external {
		bool found;
		for (uint256 i; i < receiverAddresses.length; i++) {
			if (receiverAddresses[i] == _msgSender()) {
				receiverAddresses[i] = newAddress;
				found = true;
				break;
			}
		}
		if (!found) revert NotAllowed();

		team[newAddress] = team[_msgSender()];
		delete team[_msgSender()];
	}

	/**
	 * @dev Send an amount of value to a specific address
	 * @param to_ address that will receive the value
	 * @param value to be sent to the address
	 */
	function _sendValueTo(address to_, uint256 value) internal {
		address payable to = payable(to_);
		(bool success, ) = to.call{ value: value }("");
		if (!success) revert ETHTransferFailed();
	}
}
