pragma solidity ^0.5.0;

/*
MMMMMMMM               MMMMMMMM     OOOOOOOOO          OOOOOOOOO     NNNNNNNN        NNNNNNNNDDDDDDDDDDDDD                  AAA           YYYYYYY       YYYYYYY      222222222222222                 000000000     
M:::::::M             M:::::::M   OO:::::::::OO      OO:::::::::OO   N:::::::N       N::::::ND::::::::::::DDD              A:::A          Y:::::Y       Y:::::Y     2:::::::::::::::22             00:::::::::00   
M::::::::M           M::::::::M OO:::::::::::::OO  OO:::::::::::::OO N::::::::N      N::::::ND:::::::::::::::DD           A:::::A         Y:::::Y       Y:::::Y     2::::::222222:::::2          00:::::::::::::00 
M:::::::::M         M:::::::::MO:::::::OOO:::::::OO:::::::OOO:::::::ON:::::::::N     N::::::NDDD:::::DDDDD:::::D         A:::::::A        Y::::::Y     Y::::::Y     2222222     2:::::2         0:::::::000:::::::0
M::::::::::M       M::::::::::MO::::::O   O::::::OO::::::O   O::::::ON::::::::::N    N::::::N  D:::::D    D:::::D       A:::::::::A       YYY:::::Y   Y:::::YYY                 2:::::2         0::::::0   0::::::0
M:::::::::::M     M:::::::::::MO:::::O     O:::::OO:::::O     O:::::ON:::::::::::N   N::::::N  D:::::D     D:::::D     A:::::A:::::A         Y:::::Y Y:::::Y                    2:::::2         0:::::0     0:::::0
M:::::::M::::M   M::::M:::::::MO:::::O     O:::::OO:::::O     O:::::ON:::::::N::::N  N::::::N  D:::::D     D:::::D    A:::::A A:::::A         Y:::::Y:::::Y                  2222::::2          0:::::0     0:::::0
M::::::M M::::M M::::M M::::::MO:::::O     O:::::OO:::::O     O:::::ON::::::N N::::N N::::::N  D:::::D     D:::::D   A:::::A   A:::::A         Y:::::::::Y              22222::::::22           0:::::0 000 0:::::0
M::::::M  M::::M::::M  M::::::MO:::::O     O:::::OO:::::O     O:::::ON::::::N  N::::N:::::::N  D:::::D     D:::::D  A:::::A     A:::::A         Y:::::::Y             22::::::::222             0:::::0 000 0:::::0
M::::::M   M:::::::M   M::::::MO:::::O     O:::::OO:::::O     O:::::ON::::::N   N:::::::::::N  D:::::D     D:::::D A:::::AAAAAAAAA:::::A         Y:::::Y             2:::::22222                0:::::0     0:::::0
M::::::M    M:::::M    M::::::MO:::::O     O:::::OO:::::O     O:::::ON::::::N    N::::::::::N  D:::::D     D:::::DA:::::::::::::::::::::A        Y:::::Y            2:::::2                     0:::::0     0:::::0
M::::::M     MMMMM     M::::::MO::::::O   O::::::OO::::::O   O::::::ON::::::N     N:::::::::N  D:::::D    D:::::DA:::::AAAAAAAAAAAAA:::::A       Y:::::Y            2:::::2                     0::::::0   0::::::0
M::::::M               M::::::MO:::::::OOO:::::::OO:::::::OOO:::::::ON::::::N      N::::::::NDDD:::::DDDDD:::::DA:::::A             A:::::A      Y:::::Y            2:::::2       222222        0:::::::000:::::::0
M::::::M               M::::::M OO:::::::::::::OO  OO:::::::::::::OO N::::::N       N:::::::ND:::::::::::::::DDA:::::A               A:::::A  YYYY:::::YYYY         2::::::2222222:::::2 ......  00:::::::::::::00 
M::::::M               M::::::M   OO:::::::::OO      OO:::::::::OO   N::::::N        N::::::ND::::::::::::DDD A:::::A                 A:::::A Y:::::::::::Y         2::::::::::::::::::2 .::::.    00:::::::::00   
MMMMMMMM               MMMMMMMM     OOOOOOOOO          OOOOOOOOO     NNNNNNNN         NNNNNNNDDDDDDDDDDDDD   AAAAAAA                   AAAAAAAYYYYYYYYYYYYY         22222222222222222222 ......      000000000 
https://medium.com/@marcelimpeypro1/moon-mission-64bb1bb515f1
/*


/*
 * @title: MOONDAY2.0
 * 2% burn to fuel our rockets.
 * We are just trying to go to the Moon.
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

contract MOONDAY is ERC20Detailed {

  using SafeMath for uint256;
  mapping (address => uint256) public _MOONDAYTokenBalances;
  mapping (address => mapping (address => uint256)) public _allowed;
  string constant tokenName = "moonday2.0.finance";
  string constant tokenSymbol = "MOONDAY2.0";
  uint8  constant tokenDecimals = 18;
  uint256 _totalSupply = 1969000000000000000000;


  constructor() public payable ERC20Detailed(tokenName, tokenSymbol, tokenDecimals) {
    _mint(msg.sender, _totalSupply);
  }

  function totalSupply() public view returns (uint256) {
    return _totalSupply;
  }

  function balanceOf(address owner) public view returns (uint256) {
    return _MOONDAYTokenBalances[owner];
  }


  function transfer(address to, uint256 value) public returns (bool) {
    require(value <= _MOONDAYTokenBalances[msg.sender]);
    require(to != address(0));

    uint256 MOONDAYTokenDecay = value.div(200);
    uint256 tokensToTransfer = value.sub(MOONDAYTokenDecay);

    _MOONDAYTokenBalances[msg.sender] = _MOONDAYTokenBalances[msg.sender].sub(value);
    _MOONDAYTokenBalances[to] = _MOONDAYTokenBalances[to].add(tokensToTransfer);

    _totalSupply = _totalSupply.sub(MOONDAYTokenDecay);

    emit Transfer(msg.sender, to, tokensToTransfer);
    emit Transfer(msg.sender, address(0), MOONDAYTokenDecay);
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
    require(value <= _MOONDAYTokenBalances[from]);
    require(value <= _allowed[from][msg.sender]);
    require(to != address(0));

    _MOONDAYTokenBalances[from] = _MOONDAYTokenBalances[from].sub(value);

    uint256 MOONDAYTokenDecay = value.div(100);
    uint256 tokensToTransfer = value.sub(MOONDAYTokenDecay);

    _MOONDAYTokenBalances[to] = _MOONDAYTokenBalances[to].add(tokensToTransfer);
    _totalSupply = _totalSupply.sub(MOONDAYTokenDecay);

    _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);

    emit Transfer(from, to, tokensToTransfer);
    emit Transfer(from, address(0), MOONDAYTokenDecay);

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
    _MOONDAYTokenBalances[account] = _MOONDAYTokenBalances[account].add(amount);
    emit Transfer(address(0), account, amount);
  }

  function burn(uint256 amount) external {
    _burn(msg.sender, amount);
  }

  function _burn(address account, uint256 amount) internal {
    require(amount != 0);
    require(amount <= _MOONDAYTokenBalances[account]);
    _totalSupply = _totalSupply.sub(amount);
    _MOONDAYTokenBalances[account] = _MOONDAYTokenBalances[account].sub(amount);
    emit Transfer(account, address(0), amount);
  }

  function burnFrom(address account, uint256 amount) external {
    require(amount <= _allowed[account][msg.sender]);
    _allowed[account][msg.sender] = _allowed[account][msg.sender].sub(amount);
    _burn(account, amount);
  }
}