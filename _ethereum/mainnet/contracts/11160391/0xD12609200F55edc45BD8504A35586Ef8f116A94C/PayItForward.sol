/*
 PayItForward
 2% to previousSender
 2% to the transaction before them
 1% to dev wallet for marketing
 
 Contract created by Rusty Shackleford


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

  function decimals() public view returns(uint8) {
    return _decimals;
  }
}

contract PayItForward is ERC20Detailed {

  using SafeMath for uint256;
  mapping (address => uint256) private _balances;
  mapping (address => mapping (address => uint256)) private _allowed;

  address devWallet = 0x881898e48608c72a9132fc123C339FeE8FF96973;
  address[] pifWallets = [devWallet, devWallet, devWallet];
  string constant tokenName = "PIF.money";
  string constant tokenSymbol = "PIF";
  uint8  constant tokenDecimals = 18;
  uint256 public _totalSupply = 8888000000000000000000;
  uint256 public basePercent = 5;
  bool public pifMode = false;

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

  function amountToTake(uint256 value) public view returns (uint256)  {
    uint256 amountLost = value.mul(basePercent).div(100);
    return amountLost;
  }

  function transfer(address to, uint256 value) public returns (bool) {
    require(value <= _balances[msg.sender]);
    require(to != address(0));

    _balances[msg.sender] = _balances[msg.sender].sub(value);

    if (pifMode){
        address previousSender = pifWallets[0];
        pifWallets[0] = pifWallets[1];
        pifWallets[1] = msg.sender;
        uint256 totalPIF = amountToTake(value);
        uint256 tokensToPIF = totalPIF.div(5).mul(2);
        uint256 tokensToDev = totalPIF.div(5);
        uint256 tokensToTransfer = value.sub(totalPIF);

        _balances[to] = _balances[to].add(tokensToTransfer);
        _balances[previousSender] = _balances[previousSender].add(tokensToPIF);
        _balances[pifWallets[0]] = _balances[pifWallets[0]].add(tokensToPIF);
        _balances[devWallet] = _balances[devWallet].add(tokensToDev);


        emit Transfer(msg.sender, to, tokensToTransfer);
        emit Transfer(msg.sender, previousSender, tokensToPIF);
        emit Transfer(msg.sender, pifWallets[0], tokensToPIF);
        emit Transfer(msg.sender, devWallet, tokensToDev);

    }
    else{
        _balances[to] = _balances[to].add(value);
        emit Transfer(msg.sender, to, value);
    }

    return true;
  }

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

    if (pifMode){
        address previousSender = pifWallets[0];
        pifWallets[0] = pifWallets[1];
        pifWallets[1] = from;
        uint256 totalPIF = amountToTake(value);
        uint256 tokensToPIF = totalPIF.div(5).mul(2);
        uint256 tokensToDev = totalPIF.div(5);
        uint256 tokensToTransfer = value.sub(totalPIF);

        _balances[to] = _balances[to].add(tokensToTransfer);
        _balances[previousSender] = _balances[previousSender].add(tokensToPIF);
        _balances[pifWallets[0]] = _balances[pifWallets[0]].add(tokensToPIF);
        _balances[devWallet] = _balances[devWallet].add(tokensToDev);
   

        _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);

        emit Transfer(from, to, tokensToTransfer);
        emit Transfer(from, previousSender, tokensToPIF);
        emit Transfer(from, pifWallets[0], tokensToPIF);
        emit Transfer(from, devWallet, tokensToDev);

    }
    else{
        _balances[to] = _balances[to].add(value);
        emit Transfer(from, to, value);
    }
    return true;
  }

  function increaseAllowance(address spender, uint256 addedValue) public {
    require(spender != address(0));
    _allowed[msg.sender][spender] = (_allowed[msg.sender][spender].add(addedValue));
    emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
  }

  function decreaseAllowance(address spender, uint256 subtractedValue)  public {
    require(spender != address(0));
    _allowed[msg.sender][spender] = (_allowed[msg.sender][spender].sub(subtractedValue));
    emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
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

  function enablePIFMode() public {
    require (msg.sender == devWallet);
    pifMode = true;
  }
  
    function disablePIFMode() public {
    require (msg.sender == devWallet);
    pifMode = false;
  }
}