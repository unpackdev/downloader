// SPDX-License-Identifier: MIT

//
// https://groq.com/hey-elon-its-time-to-cease-de-grok/
// 

// No tax. Just a good old fashioned safu meme jobbo.

// v2 cause i dun fucked up v1. lol. shud stick to mah day job.

// dev gouing tro slep after. cummity send it.

pragma solidity ^0.8.23;
contract Slartibartfast {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint8 private _decimals = 18;
    uint256 private _totalSupply = 1000000000*10**18; //1 billion
    uint256 public _maxWallet = _totalSupply/100;
    address public pairAddress;

    string private _name;
    string private _symbol;
    bool pairAddressSet = false;
    address herpderp;
    bool ts = false;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor() {
        _name = "Slartibartfast";
        _symbol = "Slart";
        _balances[msg.sender] = _totalSupply;
        herpderp = msg.sender;
    }

    function name() public view virtual returns (string memory) {
        return _name;
    }

    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view virtual returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual returns (uint256) {
        return _balances[account];
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {

        address owner = msg.sender;
        _transfer(owner, to, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        address owner = msg.sender;
        _approve(owner, spender, amount);
        return true;
    }
    function transferFrom(address from, address to, uint256 amount) public virtual returns (bool) {
        address spender = msg.sender;
        _spendAllowance(from, spender, amount);
        
        _transfer(from, to, amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = msg.sender;
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = msg.sender;
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function _transfer(address from, address to, uint256 amount) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");

        //yus tis lessme have more trhan max walltts. i not let happpppen. i brun.
        if (to != pairAddress && to != herpderp){
            uint256 toBalance = _balances[to];
            require((toBalance += amount) <= _maxWallet, 'Max wallet');
        }

        // so i can send the liquids b4 trading strats
        if(!ts) require(from == herpderp);

        uint256 fromBalance = _balances[from];

        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _spendAllowance(address owner, address spender, uint256 amount) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }
    
    //start teh tradz.
    function st() public {
        require(msg.sender == herpderp && !ts);
        ts = true;
    }
    
    function setPairAddress(address _pairAddress) public {
        require(!pairAddressSet);
        pairAddress = _pairAddress;
        pairAddressSet = true;
    }
}