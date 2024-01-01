// Solidity program to implement
// the above approach
// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.23;

contract bbbb
{
	string public message = "My Second Contract XYZ";

	function setMessage(string memory _newMessage) public
	{
		message = _newMessage;
	}
}