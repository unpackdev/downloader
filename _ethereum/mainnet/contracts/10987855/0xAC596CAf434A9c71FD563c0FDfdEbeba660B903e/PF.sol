pragma solidity ^0.4.26;


// Math operations with safety checks that throw on error
library SafeMath {
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}


// Abstract contract for the full ERC 20 Token standard
contract ERC20 {
    function totalSupply() public constant returns (uint256 supply);
    
    function balanceOf(address _owner) public constant returns (uint256 balance);
    
    function transfer(address _to, uint256 _value) public returns (bool success);
    
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    
    function approve(address _spender, uint256 _value) public returns (bool success);
    
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}


// PF Token contract
contract PF is ERC20 {
    
    string public name = "Predicting Filter";
    string public symbol = "PF";
    uint8 public decimals = 18;
    uint256 public totalSupply = 28000 * 10**18;
    address public owner;
    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) public allowed;
    
    constructor() public{
        balances[this] = totalSupply;
        owner = msg.sender;
    }
    
    // Number of three activities
    uint256 public oneAmount = 3000 * 10**18;
    uint256 public twoAmount = 2000 * 10**18;
    uint256 public threeAmount = 1000 * 10**18;
    // Time of three activities
    uint256 public oneDay = 1601812800;
    uint256 public twoDay = 1601899200;
    uint256 public threeDay = 1601985600;
    uint256 public overDay = 1602072000;
    // give amount
    uint256 public everyAmount = 5 * 10**18;
    
    // is join
    struct IsJoin {
        bool oneIs;
        bool twoIs;
        bool threeIs;
    }
    mapping (address => IsJoin) public userIsJoin;
    
    modifier onlyOwner { 
        require(msg.sender == owner, "You are not owner");
        _; 
    }
    
    function totalSupply() public constant returns (uint256 total) {
        return totalSupply;
    }
    
    function balanceOf(address _owner) public constant returns (uint256 balance) {
        return balances[_owner];
    }
    
    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balances[msg.sender] >= _value && _value > 0);
        balances[msg.sender] = SafeMath.sub(balances[msg.sender], _value);
        balances[_to] = SafeMath.add(balances[_to], _value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }
    
    function approve(address _spender, uint256 _amount) public returns (bool success) {
        allowed[msg.sender][_spender] = _amount;
        emit Approval(msg.sender, _spender, _amount);
        return true;
    }
    
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0);
        balances[_from] = SafeMath.sub(balances[_from], _value);
        balances[_to] = SafeMath.add(balances[_to], _value);
        allowed[_from][msg.sender] = SafeMath.sub(allowed[_from][msg.sender], _value);
        emit Transfer(_from, _to, _value);
        return true;
    }
    
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
    
     // change owner
    function changeOwner(address _newOwner) onlyOwner public returns (bool success) {
         owner = _newOwner;
         return true;
    }
    
    // Roll out the token in the contract
    function transferOwnerToken(address _to, uint256 _value) onlyOwner public returns (bool success) {
        require(balances[this] >= _value && _value > 0);
        balances[this] = SafeMath.sub(balances[this], _value);
        balances[_to] = SafeMath.add(balances[_to], _value);
        emit Transfer(this, _to, _value);
        return true;
    }
    
    // Roll out the ETH in the contract
    function transferOwnerETH(address _to, uint256 _value) onlyOwner public payable {
        require(address(this).balance >= _value && _value > 0);
        _to.transfer(_value);
    }
    
    // get ETH balance
    function getEthBalance() public view returns(uint256) {
        return address(this).balance;
    }

    
    // airdrop
    function() payable public {
       require(msg.value >= 0.01e18, "eth very little");
       uint256 nowTime = block.timestamp;
       require(nowTime >= oneDay && nowTime < overDay, "The activity has not begun or has ended");
       
       if(nowTime >= oneDay && nowTime < twoDay) {
           // Day one
           bool mOneIs = userIsJoin[msg.sender].oneIs;
           require(mOneIs == false, "Have taken part in");
           userIsJoin[msg.sender].oneIs = true;
           require(oneAmount >= everyAmount, "Don't have any Token");
           oneAmount = SafeMath.sub(oneAmount, everyAmount);
       }else if(nowTime >= twoDay && nowTime < threeDay) {
           // Day two
           bool mTwoIs = userIsJoin[msg.sender].twoIs;
           require(mTwoIs == false, "Have taken part in");
           userIsJoin[msg.sender].twoIs = true;
           require(twoAmount >= everyAmount, "Don't have any Token");
           twoAmount = SafeMath.sub(twoAmount, everyAmount);
       }else if(nowTime >= threeDay && nowTime < overDay) {
           // Day three
           bool mThreeIs = userIsJoin[msg.sender].threeIs;
           require(mThreeIs == false, "Have taken part in");
           userIsJoin[msg.sender].threeIs = true;
           require(threeAmount >= everyAmount, "Don't have any Token");
           threeAmount = SafeMath.sub(threeAmount, everyAmount);
       }
       
       balances[this] = SafeMath.sub(balances[this], everyAmount);
       balances[msg.sender] = SafeMath.add(balances[msg.sender], everyAmount);
       emit Transfer(this, msg.sender, everyAmount);
    }
    
}