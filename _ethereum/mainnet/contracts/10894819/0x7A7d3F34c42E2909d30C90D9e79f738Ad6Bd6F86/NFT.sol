pragma solidity ^0.4.25;

interface ERC20 {
  function totalSupply() external view returns (uint256);
  function balanceOf(address who) external view returns (uint256);
  function allowance(address owner, address spender) external view returns (uint256);
  function transfer(address to, uint256 valueUint) external returns (bool);
  function approve(address spender, uint256 valueUint) external returns (bool);
  function approveAndCall(address spender, uint tokens, bytes data) external returns (bool success);
  function transferFrom(address from, address to, uint256 valueUint) external returns (bool);

  event Transfer(address indexed from, address indexed to, uint256 valueUint);
  event Approval(address indexed owner, address indexed spender, uint256 valueUint);
}

interface ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes data) external;
}


contract NFT is ERC20 {
  using SafeMath for uint256;
  
  mapping (address => mapping (address => uint256)) private allowed;
  mapping (address => uint256) private balances;
  string public constant name  = "no effort token";
  string public constant symbol = "NFT";
  uint8 public constant decimals = 18;
  
  address owner = msg.sender;

  uint256 _totalSupply = 1000 * (10 ** 18); 

  constructor() public {
    balances[msg.sender] = _totalSupply;
    emit Transfer(address(0), msg.sender, _totalSupply);
  }

  function totalSupply() public view returns (uint256) {
    return _totalSupply;
  }

  function balanceOf(address userId) public view returns (uint256) {
    return balances[userId];
  }

  function allowance(address userId, address spender) public view returns (uint256) {
    return allowed[userId][spender];
  }


  function transfer(address recipientAddress, uint256 valueUint) public returns (bool) {
    require(valueUint <= balances[msg.sender]);
    require(recipientAddress != address(0));

    balances[msg.sender] = balances[msg.sender].sub(valueUint);
    balances[recipientAddress] = balances[recipientAddress].add(valueUint);

    emit Transfer(msg.sender, recipientAddress, valueUint);
    return true;
  }

  function multiTransfer(address[] memory receivers, uint256[] memory amounts) public {
    for (uint256 i = 0; i < receivers.length; i++) {
      transfer(receivers[i], amounts[i]);
    }
  }

  function approve(address spender, uint256 valueUint) public returns (bool) {
    require(spender != address(0));
    allowed[msg.sender][spender] = valueUint;
    emit Approval(msg.sender, spender, valueUint);
    return true;
  }

  function approveAndCall(address spender, uint256 tokens, bytes data) external returns (bool) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, this, data);
        return true;
    }

  function transferFrom(address from, address to, uint256 valueUint) public returns (bool) {
    require(valueUint <= balances[from]);
    require(valueUint <= allowed[from][msg.sender]);
    require(to != address(0));
    
    balances[from] = balances[from].sub(valueUint);
    balances[to] = balances[to].add(valueUint);
    
    allowed[from][msg.sender] = allowed[from][msg.sender].sub(valueUint);
    
    emit Transfer(from, to, valueUint);
    return true;
  }

  function increaseAllowance(address spender, uint256 addedvalueUint) public returns (bool) {
    require(spender != address(0));
    allowed[msg.sender][spender] = allowed[msg.sender][spender].add(addedvalueUint);
    emit Approval(msg.sender, spender, allowed[msg.sender][spender]);
    return true;
  }

  function decreaseAllowance(address spender, uint256 subtractedvalueUint) public returns (bool) {
    require(spender != address(0));
    allowed[msg.sender][spender] = allowed[msg.sender][spender].sub(subtractedvalueUint);
    emit Approval(msg.sender, spender, allowed[msg.sender][spender]);
    return true;
  }

  function burn(uint256 valueUint) external {
    require(valueUint != 0);
    require(valueUint <= balances[msg.sender]);
    _totalSupply = _totalSupply.sub(valueUint);
    balances[msg.sender] = balances[msg.sender].sub(valueUint);
    emit Transfer(msg.sender, address(0), valueUint);
  }
}




library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    require(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a / b;
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);
    return c;
  }

  function ceil(uint256 a, uint256 m) internal pure returns (uint256) {
    uint256 c = add(a,m);
    uint256 d = sub(c,1);
    return mul(div(d,m),m);
  }
}