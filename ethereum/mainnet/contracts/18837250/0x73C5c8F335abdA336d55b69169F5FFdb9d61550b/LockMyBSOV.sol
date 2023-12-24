pragma solidity 0.5.9;

// Sovcube TimeLock, & Slow Release & Timelocked Giveaway Contract
// 
//
// DO NOT SEND TOKENS DIRECTLY TO THIS CONTRACT!!!
// THEY WILL BE LOST FOREVER!!!
// YOU HAVE TO MAKE A CALL TO THE CONTRACT TO BE ABLE TO DEPOSIT & WITHDRAW!!!
//
// This contract locks deposited BSOV Tokens for 1000 days from the day the contract is deployed. Tokens can be added at any TimeLock
// within that period without resetting the timer.
// Once the users have timelocked their tokens, they are able to giveaway timelocked tokens to anyone,
// they can even batch several addresses into one giveaway-transaction.
//
// After the desired date is reached, users can withdraw tokens with a rate limit to prevent all holders
// from withdrawing and selling at the same time. The limit is 100 BSoV per week per user once the 1000 days is hit.

library SafeMath {
    function add(uint a, uint b) internal pure returns(uint c) {
        c = a + b;
        require(c >= a);
    }
    function sub(uint a, uint b) internal pure returns(uint c) {
        require(b <= a);
        c = a - b;
    }
    function mul(uint a, uint b) internal pure returns(uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function div(uint a, uint b) internal pure returns(uint c) {
        require(b > 0);
        c = a / b;
    }
}

contract ERC20Interface {
    function totalSupply() public view returns(uint);
    function balanceOf(address tokenOwner) public view returns(uint balance);
    function allowance(address tokenOwner, address spender) public view returns(uint remaining);
    function transfer(address to, uint tokens) public returns(bool success);
    function approve(address spender, uint tokens) public returns(bool success);
    function transferFrom(address from, address to, uint tokens) public returns(bool success);
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract LockMyBSOV {

    using SafeMath for uint;
    
    address constant tokenContract = 0x26946adA5eCb57f3A1F91605050Ce45c482C9Eb1; // The BSOV Token contract

    uint constant PRECISION = 100000000;
    uint constant timeUntilUnlocked = 1000 days;            // All tokens locked for 1000 days after contract creation.
    uint constant maxWithdrawalAmount = 100 * PRECISION;  // Max withdrawal of 100 tokens per week per user once 1000 days is hit.
    uint constant timeBetweenWithdrawals = 7 days;
    uint unfreezeDate;

	mapping (address => uint) balance;
	mapping (address => uint) lastWithdrawal;

    event TokensFrozen (
        address indexed addr,
        uint256 amt,
        uint256 time
	);

    event TokensUnfrozen (
        address indexed addr,
        uint256 amt,
        uint256 time
	);

    constructor() public {
        unfreezeDate = now + timeUntilUnlocked;
    }

    function withdraw(uint _amount) public {
        require(balance[msg.sender] >= _amount, "You do not have enough tokens!");
        require(now >= unfreezeDate, "Tokens are locked!");
        require(_amount <= maxWithdrawalAmount, "Trying to withdraw too much at once!");
        require(now >= lastWithdrawal[msg.sender] + timeBetweenWithdrawals, "Trying to withdraw too frequently!");
        require(ERC20Interface(tokenContract).transfer(msg.sender, _amount), "Could not withdraw BSoV!");

        balance[msg.sender] -= _amount;
        lastWithdrawal[msg.sender] = now;
        emit TokensUnfrozen(msg.sender, _amount, now);
    }

    function getBalance(address _addr) public view returns (uint256 _balance) {
        return balance[_addr];
    }
    
 function giveawayTimeLockedTokens(address[] memory _receivers, uint[] memory _amounts) public {
    require(_receivers.length == _amounts.length, "Mismatched array lengths");

    uint senderBalance = balance[msg.sender];
    uint totalAmount = 0;
    for (uint i = 0; i < _amounts.length; i++) {
        totalAmount += _amounts[i]; 
        require(totalAmount <= senderBalance, "Insufficient balance");
    }

    for (uint i = 0; i < _receivers.length; i++) {
        address receiver = _receivers[i];
        uint amount = _amounts[i];
        balance[receiver] += amount;

        emit TokensFrozen(receiver, amount, now); 
    }
    balance[msg.sender] -= totalAmount;
}


    function getLastWithdrawal(address _addr) public view returns (uint256 _lastWithdrawal) {
        return lastWithdrawal[_addr];
    }
   
    function getTimeLeft() public view returns (uint256 _timeLeft) {
        require(unfreezeDate > now, "The future is here!");
        return unfreezeDate - now;
    } 
    
    function receiveApproval(address _sender, uint256 _value, address _tokenContract, bytes memory _extraData) public {
        require(_tokenContract == tokenContract, "Can only deposit BSoV into this contract!");
        require(_value > 100, "Must be greater than 100 Mundos to keep people from whining about the math!");
        require(ERC20Interface(tokenContract).transferFrom(_sender, address(this), _value), "Could not transfer BSoV to Time Lock contract address.");

        uint _adjustedValue = _value.mul(99).div(100);
        balance[_sender] += _adjustedValue;
        emit TokensFrozen(_sender, _adjustedValue, now);
    }
}