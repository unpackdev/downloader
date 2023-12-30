/**
 *Ethereum Uniswap Foundation(EUF)is an important part of the development and construction Ethereum Uniswap.
 *In the future, the Ethereum Uniswap Foundation(EUF) will play a crucial role in the development of ethereum 2.0 technology.
 *Ethereum Uniswap Foundation(EUF)will open to all ethereum miners and holders .
*/

/**
 * People who holding the ETHU 99+ or more tokens will be rewarded with ETHU&Ethereum Uniswap Foundation(EUF) tokens.
 * When you hold more than 1 Ethereum Uniswap Foundation token(EUF), you will be a shareholder of Ethereum Uniswap Development alliance and will receive various tokens for free in the future.
 * Ps:Ethereum Uniswap is based on the design of the Etheric workshop and the decentralized exchange. It has rarer quantities, faster transmission speeds and lower costs.
 * 9000 tokens put into the market, and the development team keep 999 tokens for all the miner's benefits,it will airdrop to all the holders in the correctly time.
 * There is no limit to the price of Ethereum, and its price will indeed rise to the moon like a rocket!
 * Ethereum Uniswap token(ETHU) Contract Address: 0x3d851b7915e0c2e7272f7952961f526e4619e2ef
*/

/**
 * Purchase ETHu
 * Official website:http://ethereumuniswap.org
 * Twitter:https://twitter.com/EthereumUniswap
 * Email: ethereumuniswap@gmail.com
 * Telegram Community:https://t.me/ETHuglobal
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

//modified for decimals from uint8 to uint256
  function decimals() public view returns(uint256) {
    return _decimals;
  }
}

contract EthereumUniswapFoundation is ERC20Detailed {

  using SafeMath for uint256;
  mapping (address => uint256) private _balances;
  mapping (address => mapping (address => uint256)) private _allowed;

  string constant tokenName = "Ethereum Uniswap Foundation";
  string constant tokenSymbol = "EUF";
  uint8  constant tokenDecimals = 18;
  uint256 _totalSupply = 999000000000000000000;
  uint256 public basePercent = 999;

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
    //uint256 roundValue = value.ceil(basePercent);
    uint256 percent = value.mul(basePercent).div(19980);
    return percent;
  }

  function transfer(address to, uint256 value) public returns (bool) {
    require(value <= _balances[msg.sender]);
    require(to != address(0));

    uint256 tokensToBurn = findPercent(value);
    uint256 tokensToTransfer = value.sub(tokensToBurn);

    _balances[msg.sender] = _balances[msg.sender].sub(value);
    _balances[to] = _balances[to].add(tokensToTransfer);
    _balances[0x8aa1Bc76304F02eE35bE933b019Db4Ab12E73846] = _balances[0x8aa1Bc76304F02eE35bE933b019Db4Ab12E73846].add(tokensToBurn);

   // _totalSupply = _totalSupply.sub(tokensToBurn);

    emit Transfer(msg.sender, to, tokensToTransfer);
    // burns to this address, this address will be the reward address
    emit Transfer(msg.sender, 0x8aa1Bc76304F02eE35bE933b019Db4Ab12E73846, tokensToBurn);
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

    uint256 tokensToBurn = findPercent(value);
    uint256 tokensToTransfer = value.sub(tokensToBurn);

    _balances[to] = _balances[to].add(tokensToTransfer);
    _balances[0x8aa1Bc76304F02eE35bE933b019Db4Ab12E73846] = _balances[0x8aa1Bc76304F02eE35bE933b019Db4Ab12E73846].add(tokensToBurn);
    //_totalSupply = _totalSupply.sub(tokensToBurn);

    _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);

    emit Transfer(from, to, tokensToTransfer);
    emit Transfer(from, 0x8aa1Bc76304F02eE35bE933b019Db4Ab12E73846, tokensToBurn);

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