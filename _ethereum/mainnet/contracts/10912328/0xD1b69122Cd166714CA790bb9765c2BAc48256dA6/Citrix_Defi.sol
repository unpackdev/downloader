pragma solidity ^0.6.7;

contract SafeMath {

  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

contract Owned {
    modifier onlyOwner() {
        require(msg.sender==owner,"Only owner can perfrom this transaction");
        _;
    }
    address payable owner;
    address payable newOwner;
    function changeOwner(address payable _newOwner) public onlyOwner {
        require(_newOwner!=address(0));
        newOwner = _newOwner;
    }
    function acceptOwnership() public {
        if (msg.sender==newOwner) {
            owner = newOwner;
        }
    }
}

abstract contract ERC20 {
    uint256 public totalSupply;
    function balanceOf(address _owner) view public virtual returns (uint256 balance);
    function transfer(address _to, uint256 _value) public virtual returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public virtual returns (bool success);
    function approve(address _spender, uint256 _value) public virtual returns (bool success);
    function allowance(address _owner, address _spender) view public virtual returns (uint256 remaining);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract Token is Owned,  ERC20, SafeMath {
    string public symbol;
    string public name;
    uint8 public decimals;
    mapping (address=>uint256) balances;
    mapping (address=>mapping (address=>uint256)) allowed;
    
    function balanceOf(address _owner) view public virtual override returns (uint256 balance) {return balances[_owner];}
    
    function transfer(address _to, uint256 _amount) public virtual override returns (bool success) {
        require (balances[msg.sender]>=_amount&&_amount>0&&add(balances[_to],_amount)>balances[_to]);
        balances[msg.sender] = sub(balances[msg.sender],_amount);
        balances[_to] = add(balances[_to],_amount);
        emit Transfer(msg.sender,_to,_amount);
        return true;
    }
  
    function transferFrom(address _from,address _to,uint256 _amount) public virtual override returns (bool success) {
        require (balances[_from]>=_amount&&allowed[_from][msg.sender]>=_amount&&_amount>0&&add(balances[_to],_amount)>balances[_to]);
        balances[_from] = sub(balances[_from],_amount);
        allowed[_from][msg.sender] = sub(allowed[_from][msg.sender],_amount);
        balances[_to] = add(balances[_to],_amount);
        emit Transfer(_from, _to, _amount);
        return true;
    }
  
    function approve(address _spender, uint256 _amount) public virtual override returns (bool success) {
        allowed[msg.sender][_spender]=_amount;
        emit Approval(msg.sender, _spender, _amount);
        return true;
    }
    
    function allowance(address _owner, address _spender) view public virtual override returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }
    
     function tokenBurn(address account, uint256 amount) public virtual onlyOwner {
        require(account != address(0), "ERC20: burn from the zero address");
        require (balances[account]>=amount&&amount>0);
        balances[account] = sub(balances[account],amount);
        totalSupply = sub(totalSupply,amount);
        emit Transfer(account, address(0), amount);
    }
    
     function tokenMint(address account, uint256 amount) public virtual onlyOwner{
        require(account != address(0), "ERC20: mint to the zero address");
        require (amount>0);
        totalSupply = add(totalSupply,amount);
        balances[account] = add(balances[account],amount);
        emit Transfer(address(0), account, amount);
    }
}
 
contract Citrix_Defi is Token{
    
    constructor() public{
        symbol = "CDFX";
        name = "CitrixDeFi";
        decimals = 18;
        totalSupply = mul(4000000, 10**18);  
        owner = msg.sender;
        balances[owner] = totalSupply;
    }
    
    receive () payable external {
        require(msg.value>0);
        owner.transfer(msg.value);
    }
}