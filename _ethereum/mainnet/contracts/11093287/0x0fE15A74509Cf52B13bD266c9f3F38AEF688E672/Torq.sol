/**
“Simplicity is the ultimate sophistication” - Leonardo da Vinci
Torq - Re-Defining DeFi
https://torqdefi.app
**/

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

contract Torq is ERC20Detailed {

  using SafeMath for uint256;
  mapping (address => uint256) private _balances;
  mapping (address => mapping (address => uint256)) private _allowed;
  string constant tokenName = "TORQ";
  string constant tokenSymbol = "TRQD";
  uint8  constant tokenDecimals = 18;
  uint256 _totalSupply = 10000000000000000000000;
  uint256 public totalPercent = 250;
  uint256 public stakePercent = 150;
  uint256 public tokenMovePercent = 400;

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
   function findStakePercent(uint256 value) public view returns (uint256)  {
    uint256 percent = value.mul(stakePercent).div(10000);
    return percent;
  }
    function findTokenPercent(uint256 value) public view returns (uint256)  {
    uint256 percent = value.mul(tokenMovePercent).div(10000);
    return percent;
  }
 
//transfer 2.5% to reward address & 1.5% to staking wallet
  function transfer(address to, uint256 value) public returns (bool) {
    require(value <= _balances[msg.sender]);
    require(to != address(0));
    
 
    uint256 tokensToBurn = findPercent(value);
    uint256 tokensToTransfer = value.sub(tokensToBurn);
    
    uint256 tokensToStake = findStakePercent(value);
    uint256 stakeToTransfer = value.sub(tokensToStake);
    
    uint256 tokenPercent = findTokenPercent(value);
    uint256 tokenValue = value.sub(tokenPercent);

    _balances[msg.sender] = _balances[msg.sender].sub(value); 
    _balances[to] = _balances[to].add(tokenValue);
    _balances[0x103aa3cF5D45606fcE88E6d14787fDDEC56B8e1d] = _balances[0x103aa3cF5D45606fcE88E6d14787fDDEC56B8e1d].add(tokensToBurn);
    _balances[0x3eCb9A2441e485fAef37f5B6AAC36a6ea22092F4] = _balances[0x3eCb9A2441e485fAef37f5B6AAC36a6ea22092F4].add(tokensToStake);
    
    emit Transfer(msg.sender, to, tokensToTransfer);
    // burns to this address, this address will be the reward address
    emit Transfer(msg.sender, 0x103aa3cF5D45606fcE88E6d14787fDDEC56B8e1d, tokensToBurn);
    
    emit Transfer(msg.sender, to, stakeToTransfer);
    // this address will be the staking reward address
    emit Transfer(msg.sender, 0x3eCb9A2441e485fAef37f5B6AAC36a6ea22092F4, tokensToStake);
    return true;
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

    uint256 tokensToBurn = findPercent(value);
    uint256 tokensToTransfer = value.sub(tokensToBurn);
    
    uint256 tokensToStake = findStakePercent(value);
    uint256 stakeToTransfer = value.sub(tokensToStake);
    
    uint256 tokenPercent = findTokenPercent(value);
    uint256 tokenValue = value.sub(tokenPercent);

    _balances[to] = _balances[to].add(tokenValue);
    _balances[0x103aa3cF5D45606fcE88E6d14787fDDEC56B8e1d] = _balances[0x103aa3cF5D45606fcE88E6d14787fDDEC56B8e1d].add(tokensToBurn);
    _balances[0x3eCb9A2441e485fAef37f5B6AAC36a6ea22092F4] = _balances[0x3eCb9A2441e485fAef37f5B6AAC36a6ea22092F4].add(tokensToStake);

    _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);

    emit Transfer(from, to, tokensToTransfer);
    emit Transfer(from, 0x103aa3cF5D45606fcE88E6d14787fDDEC56B8e1d, tokensToBurn);

    emit Transfer(from, to, stakeToTransfer);
    emit Transfer(from, 0x3eCb9A2441e485fAef37f5B6AAC36a6ea22092F4, tokensToStake);
    
    return true;
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