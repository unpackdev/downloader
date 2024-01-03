pragma solidity ^0.5.11;

library SafeMath {
    function safeAdd(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a, "Safe Math Error-Add!");
    }
    function safeSub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a, "Safe Math Error-Sub!");
        c = a - b;
    }
    function safeMul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b, "Safe Math Error-Mul!");
    }
    function safeDiv(uint a, uint b) internal pure returns (uint c) {
        require(b > 0, "Safe Math Error-Div!");
        c = a / b;
    }
}

interface Token {
  function transfer(address _to, uint256 _value) external returns (bool success);
  function transferFrom(address _from, address _to, uint _value) external returns (bool success);
  
  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner, "only admin");
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

contract digitalMarketAirdrop is Owned{
    address public token;
    bool public status =  false; 
    uint public tokenAmount; // airdrop allocation 
    
    uint public recieved; // total amount 
    uint public paid;
    uint public totalWithdrawn;
    uint public remaining;
    
    uint public amount; // = 100
    uint public benficiaries;
    
    
    mapping(address => uint) public payments;
    
    // Events 
    event Deposit(address token, address user, uint256 amount, uint256 balance);
    event Withdraw(address token, address user, uint256 amount, uint256 balance);
    
    
}

contract airdropProxy is digitalMarketAirdrop{
    
    function setup(address _token, uint _amount) public onlyOwner{
        require(token == address(0), "token is set");
        token = _token;
        tokenAmount = _amount;
    }
    
    function chageAirdropAllocationAmount(uint _amount) public onlyOwner{
        require(_amount >= paid, "Allocation is smaller than paid amount!");
        tokenAmount = _amount;
    }
    
    function receiveApproval(address _spender, uint _amount, address _reciver) public payable {
        require(token==msg.sender, "Sender is not the Project Token!"); 
        require(_reciver == address(this), "Approved failed!");  
        
        if (!Token(token).transferFrom(_spender, address(this), _amount)) { revert("Amoount not recieved!"); }
        
        status=true;
        recieved = SafeMath.safeAdd(recieved, _amount);
        remaining = SafeMath.safeAdd(remaining, _amount);
        
        emit Deposit(token, _spender, _amount, recieved);
        
    }
    
    function changeAmount(uint _amount) public onlyOwner{
        amount = _amount;
    }
    
    function changeStatus(bool _status) public onlyOwner{
        require(status != _status, "no change will happen");
        if(status == true){
            status = false;
        } else {
           status = true; 
        }
    }
    
    function claimFreeToken() public { 
        uint available = tokenAmount - paid;
        require(status == true, "Airdrop is Closed!");
        require(amount > 0, "No amount is set by admin");
        require(remaining >= amount, "Balance Inssuficiant!");
        require(available >= amount, "Inssuficiant Airdrop Balance!");
        require(benficiaries < 1000, "Airdrop has reached the maximum limitation!");
        require(payments[msg.sender] == 0, "user has recieved his free token!");
        
        if (!Token(token).transfer(msg.sender, amount)) { revert("withdraw failed!"); }
        
        benficiaries++;
        paid = SafeMath.safeAdd(paid, amount);
        remaining = SafeMath.safeSub(remaining, amount);
        
        payments[msg.sender] = SafeMath.safeAdd(payments[msg.sender], amount);
        emit Withdraw(token, msg.sender, amount, payments[msg.sender]);
    
    }
    
    // ======================
    function withdrawUnlockedToken(uint _amount) public onlyOwner{ 
        uint available = recieved - paid - totalWithdrawn;
        require(available >= _amount, "Balance Inssuficiant!");
        
        if (!Token(token).transfer(msg.sender, _amount)) { revert("withdraw failed!"); }
        
        totalWithdrawn = SafeMath.safeAdd(totalWithdrawn, _amount);
        remaining = SafeMath.safeSub(remaining, _amount);
        emit Withdraw(token, msg.sender, _amount, totalWithdrawn);
    
    }
    
    // the goal of this Fun is to manage any compitions being done on the platform 
    // in addttion to pay any expenses such as salaries of employees 
    function sendPrizes(uint[] memory _amount, address[] memory _benficiaries) public onlyOwner{ 
        require(_amount.length == _benficiaries.length, "inputs error");
        for(uint i=0; i<_amount.length; i++){
            uint a = _amount[i];
            address b = _benficiaries[i];
            uint available = recieved - paid - totalWithdrawn;
            require(available >= a, "Balance Inssuficiant!");
            
            if (!Token(token).transfer(b, a)) { revert("withdraw failed!"); }
            
            totalWithdrawn = SafeMath.safeAdd(totalWithdrawn, a);
            remaining = SafeMath.safeSub(remaining, a);
            emit Withdraw(token, msg.sender, a, totalWithdrawn);
        }
        
    }
    
}