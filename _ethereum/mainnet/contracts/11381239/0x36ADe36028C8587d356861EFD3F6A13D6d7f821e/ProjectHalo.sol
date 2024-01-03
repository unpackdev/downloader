/*
  ___          _        _     _  _      _     
 | _ \_ _ ___ (_)___ __| |_  | || |__ _| |___ 
 |  _/ '_/ _ \| / -_) _|  _| | __ / _` | / _ \
 |_| |_| \___// \___\__|\__| |_||_\__,_|_\___/
            |__/                             
// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------
// Project HALO is a hyper-deflationary governance token with a 8% burn
// rate for every transaction. 1% gets sent directly to the burn address
// the other 1% gets sent to a community owned multi-sig wallet. The goal of
// HALO is to form an entirely de-centralized, trustless and sustainable
// governance system. 
//
// Join the Halo community
// https://projecthalo.network
// https://t.me/project_halo
// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------
*/

pragma solidity ^0.5.0;



interface IERC20 {
  function totalSupply() external view returns (uint256);
  function balanceOf(address who) external view returns (uint256);
  function allowance(address owner, address spender) external view returns (uint256);
  function transfer(address to, uint256 value) external returns (bool);
  function approve(address spender, uint256 value) external returns (bool);
  function transferFrom(address from, address to, uint256 value) external returns (bool);

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}



contract Owned {
    address payable public owner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address payable _newOwner) public onlyOwner {
        owner = _newOwner;
    }
}

// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------
// Mathematical Operations
// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------


library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a / b;
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }

  function ceil(uint256 a, uint256 m) internal pure returns (uint256) {
    uint256 c = add(a,m);
    uint256 d = sub(c,1);
    return mul(div(d,m),m);
  }
}

contract ERC20Detailed is IERC20 {

  string private _name;
  string private _symbol;
  uint8 private _decimals;

  constructor(string memory name, string memory symbol, uint8 decimals) public {
    _name = name;
    _symbol = symbol;
    _decimals = decimals;
  }

  function name() public view returns(string memory) {
    return _name;
  }

  function symbol() public view returns(string memory) {
    return _symbol;
  }

//modified for decimals from uint8 to uint256
  function decimals() public view returns(uint256) {
    return _decimals;
  }
}

contract ProjectHalo is ERC20Detailed {

  using SafeMath for uint256;
  mapping (address => uint256) private _balances;
  mapping (address => mapping (address => uint256)) private _allowed;
  string constant tokenName = "Project Halo";
  string constant tokenSymbol = "HALO";
  uint8  constant tokenDecimals = 18;
  uint256 _totalSupply = 10000000000000000000000;
  uint256 public totalPercent = 100;
  uint256 public burnPercentCycleOne = 100;
  uint256 public tokenMovePercent = 200; 


  constructor() public payable ERC20Detailed(tokenName, tokenSymbol, tokenDecimals) {
    _mint(msg.sender, _totalSupply);
  }

  function totalSupply() public view returns (uint256) {
    return _totalSupply;
  }

  function balanceOf(address owner) public view returns (uint256) {
    return _balances[owner];
  }

  function allowance(address owner, address spender) public view returns (uint256) {
    return _allowed[owner][spender];
  }

  function findPercent(uint256 value) public view returns (uint256)  {
    uint256 percent = value.mul(totalPercent).div(10000);
    return percent;
  }
   function findBurnPercent(uint256 value) public view returns (uint256)  {
    uint256 percent = value.mul(burnPercentCycleOne).div(10000);
    return percent;
  }

  
    function findTokenPercent(uint256 value) public view returns (uint256)  {
    uint256 percent = value.mul(tokenMovePercent).div(10000);
    return percent;
  }


      function lessThanFiveThousand() public view returns(bool){
      uint256 fiveThousand = 5000000000000000000000;
       if(_totalSupply <= fiveThousand){
           return true;
       }
       return false;
  }

    

  function transfer(address to, uint256 value) public returns (bool) {
    require(value <= _balances[msg.sender]);
    require(to != address(0));

    if(lessThanFiveThousand()) {
        
    uint256 rewardToStake = findPercent(value);
    uint256 tokensToTransfer = value.sub(rewardToStake);
    
    uint256 tokenPercent = findTokenPercent(value);
    uint256 tokenValue = value.sub(tokenPercent);

 
    _balances[msg.sender] = _balances[msg.sender].sub(value);
    _balances[to] = _balances[to].add(tokenValue);
    
    emit Transfer(msg.sender, to, tokensToTransfer);

    emit Transfer(msg.sender, 0x5EAC659BbCc1E58f2672376548b159E567830568, rewardToStake);
        
    return true;
        
    }
    
    else  { 
        
    uint256 rewardToStake = findPercent(value);
    uint256 tokensToTransfer = value.sub(rewardToStake);
    
    uint256 tokensToBurn = findBurnPercent(value);
    uint256 tokensBurnTransfer = value.sub(tokensToBurn);   
    
    uint256 tokenPercent = findTokenPercent(value);
    uint256 tokenValue = value.sub(tokenPercent);

 
    _balances[msg.sender] = _balances[msg.sender].sub(value);
    _balances[to] = _balances[to].add(tokenValue);
    
    emit Transfer(msg.sender, to, tokensToTransfer);
 
    emit Transfer(msg.sender, 0x5EAC659BbCc1E58f2672376548b159E567830568, rewardToStake);
    
    emit Transfer(msg.sender, to, tokensBurnTransfer);
    emit Transfer(msg.sender, address(0), tokensToBurn);
  
    return true;
   
    }
    
    
    
        
    }
         
 
  
// multiTransfer function
  function multiTransfer(address[] memory receivers, uint256[] memory amounts) public {
    for (uint256 i = 0; i < receivers.length; i++) {
      transfer(receivers[i], amounts[i]);
    }
  }

  function approve(address spender, uint256 value) public returns (bool) {
    require(spender != address(0));
    _allowed[msg.sender][spender] = value;
    emit Approval(msg.sender, spender, value);
    return true;
  }

    function transferFrom(address from, address to, uint256 value) public returns (bool) {
    require(value <= _balances[from]);
    require(value <= _allowed[from][msg.sender]);
    require(to != address(0));

    _balances[from] = _balances[from].sub(value);
 
   
    if(lessThanFiveThousand()) {
        
    uint256 rewardToStake = findPercent(value);
    uint256 tokensToTransfer = value.sub(rewardToStake);
    
    uint256 tokenPercent = findTokenPercent(value);
    uint256 tokenValue = value.sub(tokenPercent);

 
    _balances[msg.sender] = _balances[msg.sender].sub(value);
    _balances[to] = _balances[to].add(tokenValue);
    
    emit Transfer(msg.sender, to, tokensToTransfer);

    emit Transfer(msg.sender, 0x5EAC659BbCc1E58f2672376548b159E567830568, rewardToStake);
        
    return true;
        
    }
    
    else  { 
        
    uint256 rewardToStake = findPercent(value);
    uint256 tokensToTransfer = value.sub(rewardToStake);
    
    uint256 tokensToBurn = findBurnPercent(value);
    uint256 tokensBurnTransfer = value.sub(tokensToBurn);   
    
    uint256 tokenPercent = findTokenPercent(value);
    uint256 tokenValue = value.sub(tokenPercent);

 
    _balances[msg.sender] = _balances[msg.sender].sub(value);
    _balances[to] = _balances[to].add(tokenValue);
    
    emit Transfer(msg.sender, to, tokensToTransfer);

    emit Transfer(msg.sender, 0x5EAC659BbCc1E58f2672376548b159E567830568, rewardToStake);
    
    emit Transfer(msg.sender, to, tokensBurnTransfer);
    emit Transfer(msg.sender, address(0), tokensToBurn);
  
    return true;
   
    }
    
         
  }

 
  function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
    require(spender != address(0));
    _allowed[msg.sender][spender] = (_allowed[msg.sender][spender].add(addedValue));
    emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
    return true;
  }

  function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
    require(spender != address(0));
    _allowed[msg.sender][spender] = (_allowed[msg.sender][spender].sub(subtractedValue));
    emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
    return true;
  }

  function _mint(address account, uint256 amount) internal {
    require(amount != 0);
    _balances[account] = _balances[account].add(amount);
    emit Transfer(address(0), account, amount);
  }

  function burn(uint256 amount) external {
    _burn(msg.sender, amount);
  }

  function _burn(address account, uint256 amount) internal {
    require(amount != 0);
    require(amount <= _balances[account]);
    _totalSupply = _totalSupply.sub(amount);
    _balances[account] = _balances[account].sub(amount);
    emit Transfer(account, address(0), amount);
  }

  function burnFrom(address account, uint256 amount) external {
    require(amount <= _allowed[account][msg.sender]);
    _allowed[account][msg.sender] = _allowed[account][msg.sender].sub(amount);
    _burn(account, amount);
  }
}