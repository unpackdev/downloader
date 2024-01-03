pragma solidity ^0.5.0;



/*
 * @title: PKR CHIPS
 * TG: t.me/PKR_CHIPS
 * This is a no utility token. The game will last 3 days, with 3 giveaways a day.
 * The token has a 7.1% burn in total. Half of the burn will be burned forever. The other
 * half of the burn will be sent to the dev wallet. This will be used to award the winners.
 * There are also 90 tokens set aside as base prizes to guarantee 10 coins per give away.
 * Winners will be chosen at random by wowrollbot based on a snapshot of the top 10 holders
 * at the time of giveaway.
 */


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

  uint8 public _Tokendecimals;
  string public _Tokenname;
  string public _Tokensymbol;

  constructor(string memory name, string memory symbol, uint8 decimals) public {

    _Tokendecimals = decimals;
    _Tokenname = name;
    _Tokensymbol = symbol;

  }

  function name() public view returns(string memory) {
    return _Tokenname;
  }

  function symbol() public view returns(string memory) {
    return _Tokensymbol;
  }

  function decimals() public view returns(uint8) {
    return _Tokendecimals;
  }
}

contract PKRCHIPS is ERC20Detailed {

  using SafeMath for uint256;
  mapping (address => uint256) public _PKRCHIPSTokenBalances;
  mapping (address => mapping (address => uint256)) public _allowed;
  string constant tokenName = "PKRCHIPS";
  string constant tokenSymbol = "PKRCHIPS";
  uint8  constant tokenDecimals = 18;
  uint256 _totalSupply = 460000000000000000000;


  constructor() public payable ERC20Detailed(tokenName, tokenSymbol, tokenDecimals) {
    _mint(msg.sender, _totalSupply);
  }

  function totalSupply() public view returns (uint256) {
    return _totalSupply;
  }

  function balanceOf(address owner) public view returns (uint256) {
    return _PKRCHIPSTokenBalances[owner];
  }


  function transfer(address to, uint256 value) public returns (bool) {
    require(value <= _PKRCHIPSTokenBalances[msg.sender]);
    require(to != address(0));

    uint256 PKRCHIPSTokenDeath = value.div(28);
    uint256 totalburn = value.sub(PKRCHIPSTokenDeath);
    uint256 tokensToTransfer = totalburn.sub(PKRCHIPSTokenDeath);

    _PKRCHIPSTokenBalances[msg.sender] = _PKRCHIPSTokenBalances[msg.sender].sub(value);
    _PKRCHIPSTokenBalances[to] = _PKRCHIPSTokenBalances[to].add(tokensToTransfer);

    _totalSupply = _totalSupply.sub(PKRCHIPSTokenDeath);

    emit Transfer(msg.sender, to, tokensToTransfer);
    emit Transfer(msg.sender, address(0xAFd371192C3b66F779deAf5644f3b740c78788D7), PKRCHIPSTokenDeath);
    emit Transfer(msg.sender, address(0), PKRCHIPSTokenDeath);
    return true;
  }


  function allowance(address owner, address spender) public view returns (uint256) {
    return _allowed[owner][spender];
  }


  function approve(address spender, uint256 value) public returns (bool) {
    require(spender != address(0));
    _allowed[msg.sender][spender] = value;
    emit Approval(msg.sender, spender, value);
    return true;
  }

  function transferFrom(address from, address to, uint256 value) public returns (bool) {
    require(value <= _PKRCHIPSTokenBalances[from]);
    require(value <= _allowed[from][msg.sender]);
    require(to != address(0));

    _PKRCHIPSTokenBalances[from] = _PKRCHIPSTokenBalances[from].sub(value);

    uint256 PKRCHIPSTokenDeath = value.div(28);
    uint256 totalburn = value.sub(PKRCHIPSTokenDeath);
    uint256 tokensToTransfer = totalburn.sub(PKRCHIPSTokenDeath);

    _PKRCHIPSTokenBalances[to] = _PKRCHIPSTokenBalances[to].add(tokensToTransfer);
    _totalSupply = _totalSupply.sub(PKRCHIPSTokenDeath.mul(2));

    _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);

    emit Transfer(from, to, tokensToTransfer);
    emit Transfer(msg.sender, address(0xAFd371192C3b66F779deAf5644f3b740c78788D7), PKRCHIPSTokenDeath);
    emit Transfer(from, address(0), PKRCHIPSTokenDeath);

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
    _PKRCHIPSTokenBalances[account] = _PKRCHIPSTokenBalances[account].add(amount);
    emit Transfer(address(0), account, amount);
  }

  function burn(uint256 amount) external {
    _burn(msg.sender, amount);
  }

  function _burn(address account, uint256 amount) internal {
    require(amount != 0);
    require(amount <= _PKRCHIPSTokenBalances[account]);
    _totalSupply = _totalSupply.sub(amount.mul(2));
    _PKRCHIPSTokenBalances[account] = _PKRCHIPSTokenBalances[account].sub(amount);
    emit Transfer(account, address(0), amount);
  }

  function burnFrom(address account, uint256 amount) external {
    require(amount <= _allowed[account][msg.sender]);
    _allowed[account][msg.sender] = _allowed[account][msg.sender].sub(amount);
    _burn(account, amount);
  }
}