pragma solidity ^0.4.23;

contract phi_chat {
	string Message;

	function setMessage (string newMessage) public {
		Message = newMessage;
}

	function getMessage() public constant returns (string) {
		return Message;
}
		
}