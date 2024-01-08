// SPDX-License-Identifier: LGPL-3.0
pragma solidity ^0.8.9;

interface IWarrior {
	function newWarrior() external returns(uint theNewWarrior);
    function getWarriorIDByName(string calldata name) external view returns(uint);
    function nameExists(string calldata _name) external view returns(bool);
    function setName(uint warriorID, string calldata name) external;
    function ownerOf(uint _id) external view returns(address);
    function getWarriorCost() external pure returns(uint);
    function getWarriorName(uint warriorID) external view returns(string memory);
	function payWarrior(uint warriorID, uint amount, bool tax) external;
    function transferFAMEFromWarriorToWarrior(uint senderID, uint recipientID, uint amount, bool tax) external;
    function transferFAMEFromWarriorToAddress(uint warriorID, address recipient, uint amount) external;
}