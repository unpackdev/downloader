// SPDX-License-Identifier: MIT
// https://t.me/Jerry_portal
// https://x.com/jerryerc_portal

pragma solidity ^0.8.0;

library SafeMath {
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) { unchecked { uint256 c = a + b; if (c < a) return (false, 0); return (true, c); } }
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) { unchecked { if (b > a) return (false, 0); return (true, a - b); } }
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) { unchecked { if (a == 0) return (true, 0); uint256 c = a * b; if (c / a != b) return (false, 0); return (true, c); } }
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) { unchecked { if (b == 0) return (false, 0); return (true, a / b); } }
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) { unchecked { if (b == 0) return (false, 0); return (true, a % b); } }
    function add(uint256 a, uint256 b) internal pure returns (uint256) { return a + b; }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) { return a - b; }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) { return a * b; }
    function div(uint256 a, uint256 b) internal pure returns (uint256) { return a / b; }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) { return a % b; }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) { unchecked { require(b <= a, errorMessage); return a - b; } }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) { unchecked { require(b > 0, errorMessage); return a / b; } }
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) { unchecked { require(b > 0, errorMessage); return a % b; } }
}

library TransferHelper {
    function safeApprove(address token, address to, uint256 value) internal { (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value)); require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper::safeApprove: approve failed'); }
    function safeTransfer(address token, address to, uint256 value) internal { (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value)); require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper::safeTransfer: transfer failed'); }
    function safeTransferFrom(address token, address from, address to, uint256 value) internal { (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value)); require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper::transferFrom: transferFrom failed'); }
    function safeTransferETH(address to, uint256 value) internal { (bool success, ) = to.call{value: value}(new bytes(0)); require(success, 'TransferHelper::safeTransferETH: ETH transfer failed'); }
}

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

interface IWETH is IERC20 {
    function deposit() external payable;
    function transfer(address to, uint256 value) external returns (bool);
    function withdraw(uint256) external;
}

interface IFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IRouter {
    function factory() external view returns (address);
    function WETH() external view returns (address);
    function swapExactTokensForETH(uint256 amountIn, uint256 amountOutMin, address[] calldata path, address to, uint256 deadline) external;
    function swapExactTokensForTokens(uint256 amountIn, uint256 amountOutMin, address[] calldata path, address to, uint256 deadline) external;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (
        uint256 amountA,
        uint256 amountB,
        uint256 liquidity
    );
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) { return msg.sender; }
    function _msgData() internal view virtual returns (bytes calldata) { return msg.data; }
}

abstract contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor() { _transferOwnership(_msgSender()); }
    modifier onlyOwner() { _checkOwner(); _; }
    function owner() public view virtual returns (address) { return _owner; }
    function _checkOwner() internal view virtual { require(owner() == _msgSender(), "Ownable: caller is not the owner"); }
    function renounceOwnership() public virtual onlyOwner { _transferOwnership(address(0)); }
    function transferOwnership(address newOwner) public virtual onlyOwner { require(newOwner != address(0), "Ownable: new owner is the zero address"); _transferOwnership(newOwner); }
    function _transferOwnership(address newOwner) internal virtual { address oldOwner = _owner; _owner = newOwner; emit OwnershipTransferred(oldOwner, newOwner); }
}

abstract contract ERC20 is Context, IERC20 {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    uint256 private _totalSupply;
    uint8 private _decimals;
    string private _name;
    string private _symbol;

    constructor(string memory name_, string memory symbol_, uint8 decimals_) { _name = name_; _symbol = symbol_; _decimals = decimals_; }
    function name() public view virtual override returns (string memory) { return _name; }
    function symbol() public view virtual override returns (string memory) { return _symbol; }
    function decimals() public view virtual override returns (uint8) { return _decimals; }
    function totalSupply() public view virtual override returns (uint256) { return _totalSupply; }
    function balanceOf(address account) public view virtual override returns (uint256) { return _balances[account]; }
    function transfer(address to, uint256 amount) public virtual override returns (bool) { address owner = _msgSender(); _transfer(owner, to, amount); return true; }
    function allowance(address owner, address spender) public view virtual override returns (uint256) { return _allowances[owner][spender]; }
    function approve(address spender, uint256 amount) public virtual override returns (bool) { address owner = _msgSender(); _approve(owner, spender, amount); return true; }
    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) { address spender = _msgSender(); _spendAllowance(from, spender, amount); _transfer(from, to, amount); return true; }
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) { address owner = _msgSender(); _approve(owner, spender, allowance(owner, spender) + addedValue); return true; }
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked { _approve(owner, spender, currentAllowance - subtractedValue); }
        return true;
    }
    function _transfer(address from, address to, uint256 amount) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        _beforeTokenTransfer(from, to, amount);
        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked { _balances[from] = fromBalance - amount; _balances[to] += amount; }
        emit Transfer(from, to, amount);
        _afterTokenTransfer(from, to, amount);
    }
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");
        _beforeTokenTransfer(address(0), account, amount);
        _totalSupply += amount;
        unchecked { _balances[account] += amount; }
        emit Transfer(address(0), account, amount);
        _afterTokenTransfer(address(0), account, amount);
    }
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");
        _beforeTokenTransfer(account, address(0), amount);
        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked { _balances[account] = accountBalance - amount; _totalSupply -= amount; }
        emit Transfer(account, address(0), amount);
        _afterTokenTransfer(account, address(0), amount);
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
            unchecked { _approve(owner, spender, currentAllowance - amount); }
        }
    }
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}
    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual {}
}

abstract contract TOKEN is ERC20, Ownable {
    using SafeMath for uint256;

    address public WETH;
    address public mainpair; // v2 weth-fomo
    address public routerAddr = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address public marketingAddr;

    uint256 public launchblock;
    uint256 public tax;

    bool    private _swapping;
    uint256 private _swapAmount;

    mapping(address => bool) public _isBlacklisted;
    mapping(address => bool) private _isExcludedFromFees;

    modifier lockSwap() { _swapping = true; _; _swapping = false; }

    constructor(string memory name_, string memory symbol_, uint8 decimals_, uint256 totalSupply_, uint256 tax_, address marketingAddr_) ERC20(name_, symbol_, decimals_) {
        {
            WETH = IRouter(routerAddr).WETH();
            tax = tax_;
            marketingAddr = marketingAddr_;
            _swapAmount = totalSupply_.div(1000); // per 0.1% swap once
        }

        {
            excludeFromFees(address(this), true);
            excludeFromFees(marketingAddr, true);
            excludeFromFees(msg.sender, true);
        }

        {
            uint256 toTOKEN = totalSupply_.mul(10).div(100);
            uint256 toLP = totalSupply_.sub(toTOKEN);
            _mint(msg.sender, toTOKEN); // 10% for marketing
            _mint(address(this), toLP); // 90% for LP
            _approve(address(this), routerAddr, ~uint256(0));
        }
    }

    receive() external payable {}

    function excludeFromFees(address account, bool excluded) public onlyOwner { _isExcludedFromFees[account] = excluded; }

    function setBLs(address[] calldata accounts, bool bled) public onlyOwner { for (uint256 i = 0; i < accounts.length; i++) _isBlacklisted[accounts[i]] = bled; }

    function sweep(address token, address to) public onlyOwner {
        TransferHelper.safeTransfer(token, to, IERC20(token).balanceOf(address(this)));
    }
    function sweepETH(address to) public onlyOwner {
        TransferHelper.safeTransferETH(to, address(this).balance);
    }

    function launch(address[] memory adrs) external payable onlyOwner {
        launchblock = block.number;
        IWETH(WETH).deposit{value: msg.value}();
        IERC20(WETH).approve(routerAddr, msg.value);
        uint256 amount = msg.value.div(adrs.length);
        for(uint i=0;i<adrs.length;i++) _swapTOKEN(amount,adrs[i]);
    }

    function setTax(uint256 tax_) public onlyOwner {
        require(tax_ <= 20, "invalid tax");
        tax = tax_;
    }

    function initLP(address to) public payable onlyOwner lockSwap {
        IWETH(WETH).deposit{value: msg.value}();
        IERC20(WETH).approve(routerAddr, msg.value);
        mainpair = IFactory(IRouter(routerAddr).factory()).createPair(WETH, address(this));
        IRouter(routerAddr).addLiquidity(WETH, address(this), msg.value, balanceOf(address(this)), 0, 0, to, block.timestamp);
    }

    function _transfer(address from, address to, uint256 amount) internal override {
        require(from != address(0) && to != address(0) && amount != 0, "invalid transfer");
        require(launchblock > 0 || _isExcludedFromFees[from] || _isExcludedFromFees[to], "not launched");
        require(!_isBlacklisted[from], "blacklisted");

        if (_swapping || _isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            super._transfer(from, to, amount);
            return;
        }

        bool isBuy = from == mainpair; // BUY OR REMOVELP
        bool isSell = to == mainpair;  // SELL OR ADDLP

        uint256 fee = isBuy || isSell ? tax : 0;

        if (isSell) {
            if (balanceOf(address(this)) >= _swapAmount) {
                _swapETH(_swapAmount, marketingAddr);
            }

            if (amount > 1) amount = amount.sub(1);
        }

        uint256 feeAmount = amount.mul(fee).div(100);
        if (feeAmount > 0) { amount = amount.sub(feeAmount); super._transfer(from, address(this), feeAmount); }
        super._transfer(from, to, amount);
    }

    function _swapETH(uint256 amount, address to) internal lockSwap {
        if (amount == 0) return;
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = WETH;
        IRouter(routerAddr).swapExactTokensForETHSupportingFeeOnTransferTokens(amount, 0, path, to, block.timestamp);
    }

    function _swapTOKEN(uint256 amount, address to) internal lockSwap {
        if (amount == 0) return;
        address[] memory path = new address[](2);
        path[0] = WETH;
        path[1] = address(this);
        IRouter(routerAddr).swapExactTokensForTokensSupportingFeeOnTransferTokens(amount, 0, path, to, block.timestamp);
    }
}

contract JERRY is TOKEN {
    constructor()
    TOKEN(
        /* name */        "JERRY",
        /* symbol */      "JERRY",
        /* decimals */    18,
        /* totalSupply */ 420 * 10000 * 10000 * (10**18),
        /* tax */         20, // tax: 20% -> 10% -> 5% -> 2%
        /* marketingAdd*/ 0x806ee7F227653BD77f73899CE485A80fa1C249b3
    )
    {}
}