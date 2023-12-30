//Symbol: DEP
//Decimals: 18
//Total Supply: 5000000
//Website: https://dexexplorer.io
//app: https://app.dexexplorer.io

pragma solidity ^0.4.25;

library SafeMath {
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
      uint256 c = a + b;
      require(c >= a);
      return c;
  }
  
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

  function ceil(uint256 a, uint256 m) internal pure returns (uint256) {
    uint256 c = add(a,m);
    uint256 d = sub(c,1);
    return mul(div(d,m),m);
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
      require(b <= a);
      uint256 c = a - b;
      return c;
  }


}

contract ERC20 {
  function totalSupply() public view returns (uint256);
  function balanceOf(address holder) public view returns (uint256);
  function transfer(address to, uint256 amount) public returns (bool success);
  function approve(address spender, uint256 amount) public returns (bool success);
  function transferFrom(address from, address to, uint256 amount) public returns (bool success);
  function allowance(address holder, address spender) public view returns (uint256);

  event Approval(address indexed holder, address indexed spender, uint256 amount);
  event Transfer(address indexed from, address indexed to, uint256 amount);

}

contract DexExplorer is ERC20 {

    using SafeMath for uint256;

    string public symbol;
    string public name;
    uint8 public decimals;
    uint256 private _totalSupply;
    uint256 oneHundredPercent;

    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;
    
    constructor(
        uint256 _initialAmount,
        string _tokenName,
        uint8 _decimalUnits,
        string _tokenSymbol
    ) public {
        balances[msg.sender] = _initialAmount;               
        _totalSupply = _initialAmount;                        
        name = _tokenName;                                   
        decimals = _decimalUnits;                            
        symbol = _tokenSymbol;   
        oneHundredPercent = 100;
    }


    function transfer(address to, uint256 amount) public returns (bool success) {
      require(amount <= balances[msg.sender]);
      require(to != address(0));

      uint256 tokensToBurn = findOnePercent(amount);
      uint256 tokensToTransfer = amount.sub(tokensToBurn);

      balances[msg.sender] = balances[msg.sender].sub(amount);
      balances[to] = balances[to].add(tokensToTransfer);

      _totalSupply = _totalSupply.sub(tokensToBurn);

      emit Transfer(msg.sender, to, tokensToTransfer);
      emit Transfer(msg.sender, address(0), tokensToBurn);
      return true;
    }

    function approve(address spender, uint256 amount) public returns (bool success) {
        allowed[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }
    
    function totalSupply() public view returns (uint256) {
      return _totalSupply;
    }

    function balanceOf(address holder) public view returns (uint256) {
        return balances[holder];
    }

    function allowance(address holder, address spender) public view returns (uint256) {
        return allowed[holder][spender];
    }

    function findOnePercent(uint256 amount) private view returns (uint256)  {
        uint256 roundAmount = amount.ceil(oneHundredPercent);
        uint256 onePercent = roundAmount.mul(oneHundredPercent).div(10000);
        return onePercent;
    }
    
    function transferFrom(address from, address to, uint256 amount) public returns (bool success) {
      require(amount <= balances[from]);
      require(amount <= allowed[from][msg.sender]);
      require(to != address(0));

      balances[from] = balances[from].sub(amount);

      uint256 tokensToBurn = findOnePercent(amount);
      uint256 tokensToTransfer = amount.sub(tokensToBurn);

      balances[to] = balances[to].add(tokensToTransfer);
      _totalSupply = _totalSupply.sub(tokensToBurn);

      allowed[from][msg.sender] = allowed[from][msg.sender].sub(amount);

      emit Transfer(from, to, tokensToTransfer);
      emit Transfer(from, address(0), tokensToBurn);

      return true;
    }
}