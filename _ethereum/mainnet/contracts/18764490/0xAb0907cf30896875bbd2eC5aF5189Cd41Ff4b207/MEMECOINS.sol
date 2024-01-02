/*
  MEMECOINS
  https://x.com/MEMECOINSlife
  https://t.me/MEMECOINSlife
  https://t.me/MEMECOINSX
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

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

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


    constructor() {
        _transferOwnership(_msgSender());
    }


    function owner() public view virtual returns (address) {
        return _owner;
    }


    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }


    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IERC20 {

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IERC20Metadata is IERC20 {

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }


    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
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

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
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


interface IUniswapV2Router {
    function factory() external view returns (address);
    function WETH() external view returns (address);
}

interface IUniswapFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

contract MEMECOINS is ERC20, Ownable {
    address public immutable fund;
    mapping(address => bool) public whiteList;
    bool public isWhitelist = true;
    uint public buyTax = 0;
    uint public sellTax = 0;
    address public pairAddress;
    uint256 public _maxWalletToken;
    mapping(address => bool) private excludeFromMaxHold;

    constructor(
      address _fund, 
      string memory _name, 
      string memory _symbol,
      uint _totalSupply,
      address _router
    ) ERC20(_name, _symbol) 
    {
        _mint(msg.sender, _totalSupply);
        fund = _fund;

        address factory = IUniswapV2Router(_router).factory();
        address WETH = IUniswapV2Router(_router).WETH();
        address pair = IUniswapFactory(factory).createPair(address(this), WETH);
        
        // WL
        whiteList[pair] = true;
        whiteList[_router] = true;
        whiteList[fund] = true;
        
        // Max HOLD
        excludeFromMaxHold[pair] = true;
        excludeFromMaxHold[_router] = true;
        excludeFromMaxHold[fund] = true;

        pairAddress = pair;

        _maxWalletToken = _totalSupply / 100; // 1% max hold per wallet
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual override {
        // WL
        if(isWhitelist)
          require(whiteList[recipient], "not in white list");

        // Max HOLD
        if(!excludeFromMaxHold[recipient]){
          uint256 heldTokens = balanceOf(recipient);
          require((heldTokens + amount) <= _maxWalletToken,"total holding limit");
        }
          
        uint tax = 0;

        // buy tax
        if(sender == pairAddress){
          tax = buyTax;
        }
        
        // sell tax
        if(recipient == pairAddress){
          tax = sellTax;
        }
        
        // transfer with tax
        if(tax > 0){
          uint taxAmount =  (amount / 100) * tax;
          super._transfer(sender, recipient, amount - taxAmount);
          super._transfer(sender, fund, taxAmount);
        }
        // default transfer
        else{
          super._transfer(sender, recipient, amount);
        }
    }

    // enable/disable WL
    function changeWhitelistStatus(bool _isWhitelist) external onlyOwner {
      isWhitelist = _isWhitelist;
    }
    
    // add/remove address from WL
    function whitelist(address _address, bool _isWhitelisting) external onlyOwner {
        whiteList[_address] = _isWhitelisting;
    }
    
    // add/remove array addresses from WL
    function whitelistBatch(address[] memory _addresses, bool _isWhitelisting) external onlyOwner {
        for(uint i = 0; i < _addresses.length; i++){
          whiteList[_addresses[i]] = _isWhitelisting;
        }
    }

    // update buy tax
    function updateBuyTax(uint _tax) external onlyOwner {
      require(_tax <= 15, "Tax too high");
      buyTax = _tax;
    }
    
    // update sell tax
    function updateSellTax(uint _tax) external onlyOwner {
      require(_tax <= 15, "Tax too high");
      sellTax = _tax;
    }
}