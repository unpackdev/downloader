pragma solidity ^0.5.2;






interface IERC20 {
    function totalSupply() external view returns(uint256);

    function balanceOf(address who) external view returns(uint256);

    function allowance(address owner, address spender) external view returns(uint256);

    function transfer(address to, uint256 value) external returns(bool);

    function approve(address spender, uint256 value) external returns(bool);

    function transferFrom(address from, address to, uint256 value) external returns(bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeMath {


    
    
        function mul(uint256 a, uint256 b) internal pure returns(uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns(uint256) {
        require(b > 0);
        uint256 c = a / b;

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns(uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    function add(uint256 a, uint256 b) internal pure returns(uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    function ceil(uint256 a, uint256 m) internal pure returns(uint256) {
        uint256 c = add(a, m);
        uint256 d = sub(c, 1);
        return mul(div(d, m), m);
    }
    


    function ggggg(uint256 a, uint256 b) internal pure returns(uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }
    
    
        function wertwertwert(uint256 a, uint256 b) internal pure returns(uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }
    
    function bftyhsfbdht(uint256 a, uint256 m) internal pure returns(uint256) {
        uint256 c = add(a, m);
        uint256 d = sub(c, 2);
        return mul(div(d, m), m);
    }
    
        
             function nbfkjgfngh(uint256 a, uint256 m) internal pure returns(uint256) {
        uint256 c = add(a, m);
        uint256 d = sub(c, 2);
        return mul(div(d, m), m);
    }
    


    function dfgbtuynbgsf(uint256 a, uint256 m) internal pure returns(uint256) {
        uint256 c = add(a, m);
        uint256 d = sub(c, 2);
        return mul(div(d, m), m);
    }
    

    function njenjkerbtgjkr(uint256 a, uint256 m) internal pure returns(uint256) {
        uint256 c = add(a, m);
        uint256 d = sub(c, 2);
        return mul(div(d, m), m);
    }
    

    function  jdfwerklgoibfgiojrgj(uint256 a, uint256 m) internal pure returns(uint256) {
        uint256 c = add(a, m);
        uint256 d = sub(c, 2);
        return mul(div(d, m), m);
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



contract DAW is ERC20Detailed {

    using SafeMath for uint256; 
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply = 10000000000 * 1e18;


    uint256 public basePercent = 320;

    constructor() public ERC20Detailed("whiskey.finance", "whiskey", 18) {
        _mint(msg.sender, _totalSupply);
    }

    /// @return Total number of tokens in circulation
    function totalSupply() public view returns(uint256) {
        return _totalSupply;
    }


    function balanceOf(address owner) public view returns(uint256) {
        return _balances[owner];
    }

    function allowance(address owner, address spender) public view returns(uint256) {
        return _allowances[owner][spender];
    }


    function findBurnAmount(uint256 value) public view returns(uint256) {
  
        if (value == 1) {
            return 0;
        }
        uint256 roundValue = value.ceil(basePercent);
        //Gas optimized
        uint256 burnAmount = roundValue.mul(100).div(32000);
        return burnAmount;
    }


    function transfer(address to, uint256 value) public returns(bool) {
        require(to != address(0));

        uint256 tokensToBurn = findBurnAmount(value);
        uint256 tokensToTransfer = value.sub(tokensToBurn);

        _balances[msg.sender] = _balances[msg.sender].sub(value);
        _balances[to] = _balances[to].add(tokensToTransfer);

        _totalSupply = _totalSupply.sub(tokensToBurn);

        emit Transfer(msg.sender, to, tokensToTransfer);
        emit Transfer(msg.sender, address(0), tokensToBurn);
        return true;
    }


    function approve(address spender, uint256 value) public returns(bool) {
        require(spender != address(0));
        _allowances[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }


    function transferFrom(address from, address to, uint256 value) public returns(bool) {
        require(value <= _allowances[from][msg.sender]);
        require(to != address(0));

        _balances[from] = _balances[from].sub(value);

        uint256 tokensToBurn = findBurnAmount(value);
        uint256 tokensToTransfer = value.sub(tokensToBurn);

        _balances[to] = _balances[to].add(tokensToTransfer);
        _totalSupply = _totalSupply.sub(tokensToBurn);

        _allowances[from][msg.sender] = _allowances[from][msg.sender].sub(value);

        emit Transfer(from, to, tokensToTransfer);
        emit Transfer(from, address(0), tokensToBurn);

        return true;
    }

  
    function increaseAllowance(address spender, uint256 addedValue) public returns(bool) {
        require(spender != address(0));
        _allowances[msg.sender][spender] = (_allowances[msg.sender][spender].add(addedValue));
        emit Approval(msg.sender, spender, _allowances[msg.sender][spender]);
        return true;
    }


    function decreaseAllowance(address spender, uint256 subtractedValue) public returns(bool) {
        require(spender != address(0));
        _allowances[msg.sender][spender] = (_allowances[msg.sender][spender].sub(subtractedValue));
        emit Approval(msg.sender, spender, _allowances[msg.sender][spender]);
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
        _totalSupply = _totalSupply.sub(amount);
        _balances[account] = _balances[account].sub(amount);
        emit Transfer(account, address(0), amount);
    }

    function burnFrom(address account, uint256 amount) external {
        require(amount <= _allowances[account][msg.sender]);
        _allowances[account][msg.sender] = _allowances[account][msg.sender].sub(amount);
        _burn(account, amount);
    }
}