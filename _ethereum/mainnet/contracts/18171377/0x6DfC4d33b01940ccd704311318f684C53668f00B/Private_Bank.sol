pragma solidity ^0.4.24;

contract Private_Bank {
    mapping(address => uint256) balances;
    uint256 public MinDeposit = 0.1 ether;  // Just assuming this, as it's not provided
    Log TransferLog;

    function Private_Bank(address _log) public { 
        TransferLog = Log(_log); 
    } 

    function Deposit() public payable { 
        if(msg.value >= MinDeposit) { 
            balances[msg.sender] += msg.value; 
            TransferLog.AddMessage("Deposit"); 
        } 
    } 

    function CashOut(uint _am) public { 
        if(_am <= balances[msg.sender]) { 
            if(msg.sender.call.value(_am)()) { 
                balances[msg.sender] -= _am; 
                TransferLog.AddMessage("CashOut"); 
            } 
        } 
    }
} 

contract Log {
    struct Message {
        uint256 Time;
        string Data;
    }

    Message[] public History;
    Message public LastMsg;

    function AddMessage(string _data) public { 
        LastMsg.Time = now; 
        LastMsg.Data = _data; 
        History.push(LastMsg); 
    }
}