pragma solidity ^0.6.6;

contract allan {
    string public message;
    uint public no;
    
    constructor(string memory InitMsg, uint InitNo) public {
        message = InitMsg;
        no = InitNo;
    }
    
    function updateMsg(string memory NewMsg) public {
        message = NewMsg;
    }
    
    function updateNo(uint NewNo) public {
        no = NewNo;
    }
}