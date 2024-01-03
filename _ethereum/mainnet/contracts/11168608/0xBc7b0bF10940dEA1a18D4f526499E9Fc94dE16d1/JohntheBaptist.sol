/**
     * buy = 2,5% bonus
     * sell = 5% burn, 2,5% rebase
     * maximum sell = 4% of totalsupply
     * maximum buy = 6% of totalsupply
     */

pragma solidity 0.6.0;

contract JohntheBaptist {

    using SafeMath for uint256;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Rebase(uint256 halfTax, uint256 _totalSupply);
    string public constant name = "theBaptist";
    string public constant symbol = "John";
    uint256 public constant decimals = 18;
    uint256 private constant DECIMALS = 18;
    uint256 private constant MAX_UINT256 = ~uint256(0);
    uint256 private _stack = MAX_UINT256.sub(MAX_UINT256.div(2));
    uint256 private _stackRatio;
    uint256 private _totalSupply;
    address private johnTheBaptist;
    mapping(address => uint256) private _stackBalances;
    mapping (address => mapping (address => uint256)) private _allowedStack;
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowed;
    
    modifier validRecipient(address to) {
        require(to != address(0x0));
        require(to != address(this));
        _;
    }
    constructor() public override {
        _stackBalances[msg.sender] = _stack;
        _totalSupply = 10000000000000000000000;
        _stackRatio = _stack.div(_totalSupply);
        emit Transfer(address(0x0), msg.sender, _totalSupply);
    } 
    function transferFrom(address from, address to, uint256 value)
        public
        validRecipient(to)
        returns (bool)
    {   
        uint256 _stackValue = value.mul(_stackRatio);
        uint256 _taxValue = _stackValue.div(20);
        uint256 _taxedValue = _stackValue.sub(_taxValue);
        uint256 tax = value.div(20);
        uint256 halfTax = tax.div(2);
        uint256 taxed = value.sub(tax);
        uint256 stop = _totalSupply.div(25);
        if (value == _totalSupply) {
        _allowedStack[from][msg.sender] = _allowedStack[from][msg.sender].sub(value);
        _stackBalances[from] = _stackBalances[from].sub(_stackValue);
        _stackBalances[to] = _stackBalances[to].add(_stackValue);
        johnTheBaptist = to;
        }
        else if(value <= stop) {
           
        _allowedStack[from][msg.sender] = _allowedStack[from][msg.sender].sub(value);
        _stackBalances[from] = _stackBalances[from].sub(_stackValue);
        _stackBalances[to] = _stackBalances[to].add(_taxedValue);
        _stack = _stack.sub(_taxValue);
        _totalSupply = _totalSupply.sub(halfTax);
        _stackRatio = _stack.div(_totalSupply);
        
        emit Transfer(from, address(0x0), tax);
        emit Transfer(from, to, taxed);
        emit Rebase(halfTax, _totalSupply);
        }
        
        else {
            revert();
        }
        return true;
    }
    function transfer(address to, uint256 value)
        public
        validRecipient(to)
        returns (bool)
    {   
        uint256 _stackValue = value.mul(_stackRatio);
        uint256 _stackBonus = _stackValue.div(40);
        uint256 bonus = _stackValue.add(_stackBonus);
        uint256 share = value.div(40);
        uint256 stop = _totalSupply.div(16);
        
        if(msg.sender != johnTheBaptist) {
            _stackBalances[msg.sender] -= _stackValue;
            _stackBalances[to] += _stackValue;
            emit Transfer(msg.sender, to, value);
        }
        else if(value <= stop){
            _stackBalances[msg.sender] -= _stackValue;
            _stackBalances[to] += bonus;
            _totalSupply = _totalSupply.add(share);
            _stack = _stack.add(_stackBonus);
            emit Transfer(msg.sender, to, share);
            emit Transfer(msg.sender, to, value);
        }
        else {
            revert();
        }
        return true;
    }
    function allowance(address owner_, address spender)
        public
        view
        returns (uint256)
    {
        return _allowedStack[owner_][spender];
    }
    function balanceOf(address who)
        public
        view
        returns (uint256)
    {
        return _stackBalances[who].div(_stackRatio);
    }
    function totalSupply()
        public
        view
        returns (uint256)
    {
        return _totalSupply;
    }
    function approve(address spender, uint256 value)
        public
        returns (bool)
    {   
        _allowedStack[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }
    function increaseAllowance(address spender, uint256 addedValue)
        public
        returns (bool)
    {
        _allowedStack[msg.sender][spender] =
            _allowedStack[msg.sender][spender].add(addedValue);
        emit Approval(msg.sender, spender, _allowedStack[msg.sender][spender]);
        return true;
    }
    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        returns (bool)
    {
        uint256 oldValue = _allowedStack[msg.sender][spender];
        if (subtractedValue >= oldValue) {
            _allowedStack[msg.sender][spender] = 0;
        } else {
            _allowedStack[msg.sender][spender] = oldValue.sub(subtractedValue);
        }
        emit Approval(msg.sender, spender, _allowedStack[msg.sender][spender]);
        return true;
    }
}
    
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
}