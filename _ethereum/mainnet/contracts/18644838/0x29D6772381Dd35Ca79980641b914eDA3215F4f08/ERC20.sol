// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/*Finamp is a unique and replenished tool that functions as a
 telegram bot designed for more efficient and secure trading in the DeFi space.

Website: https://finamp.dev/

Twitter: https://twitter.com/steve_hawk51974

Telegram Discussion: https://t.me/finamp_portal


The official launch on the Uniswap exchange is scheduled for November 25, 2023 at 20:00 UTC. 
I look forward to this important event and hope that each of you can join and experience all the benefits I offer.*/

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed _owner, address indexed spender, uint256 value);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;
    mapping(address => bool) addressesLiquidity;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFee;

    address public owner;
    address private marketing = 0xb7cd1735248683f554e4a73Ee77722a6f49dfC43;
    uint256 private _totalSupply;
    string  private _name;
    string  private _symbol;
    uint256 public buy_fee  = 150;
    uint256 public sell_fee = 200;

    uint256 public maxBuySell;

    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }
    function setFees_15_20() public onlyOwner {                
        buy_fee  = 150;
        sell_fee = 200;
    }
    function setFees_10_10() public onlyOwner {                
        buy_fee  = 100;
        sell_fee = 100;
    }
    function setFees_1_1() public onlyOwner {                
        buy_fee  = 10;
        sell_fee = 10;
    }
    function removeAllFees() public onlyOwner {
        buy_fee  = 0;
        sell_fee = 0; 
    }
    function RemoveAllLimits() public onlyOwner {
       maxBuySell = 0;
    }
    
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = owner;
        owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function exclude_from_fee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }    
    function include_in_fee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }

    function checkAddressLiquidity(address _addressLiquidity) external view returns (bool) {
        return addressesLiquidity[_addressLiquidity];
    }
    function addAddressLiquidity(address _addressLiquidity) public onlyOwner {
        addressesLiquidity[_addressLiquidity] = true;
    }
    function removeAddressLiquidity (address _addressLiquidity) public onlyOwner {
        addressesLiquidity[_addressLiquidity] = false;
    }

    
    function changeMarketing(address newMarketing) public onlyOwner {
        marketing = newMarketing;
        _isExcludedFromFee[marketing] = true;
    }
    function checkMarketing() external view returns (address) {
        return marketing;
    }

    constructor() {
        _name = "Finamp";
        _symbol = "fnp";
        
        uint256 owner_balance = 100000000*10**5;
        _balances[msg.sender] = owner_balance;
        emit Transfer(address(0), msg.sender, owner_balance);

        _totalSupply = owner_balance;
        maxBuySell =  _totalSupply * 2 / 100;
        owner = msg.sender;

        _isExcludedFromFee[msg.sender] = true;
        _isExcludedFromFee[marketing] = true;
        _isExcludedFromFee[address(this)] = true;
    }
    function name() public view virtual override returns (string memory) {
        return _name;
    }
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    } 
    function decimals() public view virtual override returns (uint8) {
        return 5;
    }
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address _owner = _msgSender();
        _transfer(_owner, to, amount);
        return true;
    }
    function allowance(address _owner, address spender) public view virtual override returns (uint256) {
        return _allowances[_owner][spender];
    }
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address _owner = _msgSender();
        _approve(_owner, spender, amount);
        return true;
    }
    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address _owner = _msgSender();
        _approve(_owner, spender, allowance(_owner, spender) + addedValue);
        return true;
    }
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address _owner = _msgSender();
        uint256 currentAllowance = allowance(_owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_owner, spender, currentAllowance - subtractedValue);
        }
        return true;
    }

    function _transfer(address from, address to, uint256 amount) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");      
        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");

        if (_isExcludedFromFee[from] || _isExcludedFromFee[to]) {           
                _balances[from] = fromBalance - amount;
                _balances[to] += amount;        
            emit Transfer(from, to, amount);
        } else {             
                if (addressesLiquidity[to] || addressesLiquidity[from]) {
                    uint256 _this_fee;   
                    if(maxBuySell > 0) require(maxBuySell >= amount, "ERC20: The amount of the transfer is more than allowed");
                    if(addressesLiquidity[to]) _this_fee = sell_fee;
                    if(addressesLiquidity[from]) _this_fee = buy_fee;                  
                
                    uint256 _amount = amount * (1000 - _this_fee) / 1000;
                    _balances[from] = fromBalance - amount;
                    _balances[to]   += _amount;
                    emit Transfer(from, to, _amount);
            
                    uint256 _this_fee_value  = amount * _this_fee  / 1000;               
                    
                    _balances[marketing] += _this_fee_value;
                    emit Transfer(address(this), marketing, _this_fee_value);
                } else {            
                    _balances[from] = fromBalance - amount;
                    _balances[to] += amount;               
                    emit Transfer(from, to, amount);
                } 
            }
    }
    function _approve(address _owner, address spender, uint256 amount) internal virtual {
        require(_owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[_owner][spender] = amount;
        emit Approval(_owner, spender, amount);
    }
    function _spendAllowance(address _owner, address spender, uint256 amount) internal virtual {
        uint256 currentAllowance = allowance(_owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(_owner, spender, currentAllowance - amount);
            }
        }
    }
    receive() external payable {}
}