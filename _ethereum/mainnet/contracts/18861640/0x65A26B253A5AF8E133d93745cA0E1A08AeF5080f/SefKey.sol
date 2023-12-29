/*
    SEFKEY

    Website: https://sefkey.com/
    Twitter: https://twitter.com/SefkeyErc20
    Telegram: https://t.me/SefkeyERC20_Portal

*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
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

contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
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

    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function _transfer(address from, address to, uint256 amount) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            _balances[account] += amount;
        }
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
            _totalSupply -= amount;
        }

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
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}

    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual {}
}

interface DexFactory {
    function createPair(
        address tokenA,
        address tokenB
    ) external returns (address pair);
}

interface DexRouter {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

contract SefKey is ERC20, Ownable {
    struct Tax {
        uint256 marketingTax;
    }

    uint256 private constant _totalSupply = 5_000_000 * 1e18;

    DexRouter public immutable uniswapRouter;
    address public immutable pairAddress;

    Tax public buyTaxes = Tax(3);
    Tax public sellTaxes = Tax(5);
    Tax public transferTaxes = Tax(3);

    mapping(address => bool) private whitelisted;
    mapping(address => uint256) private _holderLastTransferTimestamp;

    uint256 public swapTokensAtAmount = _totalSupply / 5_000_000;
    bool public swapAndLiquifyEnabled = true;
    bool public isSwapping = false;
    bool public tradingEnabled = false;
    uint256 public startTradingBlock;
    bool public transferDelayEnabled = true;
    bool public launchTax;

    address public marketingWallet = 0x2246964dB19Db2e617944b910Bf0d705Cb4f115C ;
    
    uint256 public maxWalletPercentage = 3;

    event BuyFeesUpdated(uint256 indexed _trFee);
    event SellFeesUpdated(uint256 indexed _trFee);
    event marketingWalletChanged(address indexed _trWallet);
    event SwapThresholdUpdated(uint256 indexed _newThreshold);
    event InternalSwapStatusUpdated(bool indexed _status);
    event Whitelist(address indexed _target, bool indexed _status);
    event MaxWChanged(uint256 percentage);

    constructor() ERC20("Sefkey", "SEFK") {

        uniswapRouter = DexRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        pairAddress = DexFactory(uniswapRouter.factory()).createPair(
            address(this),
            uniswapRouter.WETH()
        );
        whitelisted[msg.sender] = true;
        whitelisted[address(uniswapRouter)] = true;
        whitelisted[address(this)] = true;       
        _mint(msg.sender, _totalSupply);
        launchTax = false;
    }

    function enableTrading() external onlyOwner {
        require(!tradingEnabled, "Trading is already enabled");
        tradingEnabled = true;
        launchTax=true;
        startTradingBlock = block.number;
    }

    function removeLimits() external onlyOwner{
        maxWalletPercentage =100;
        transferDelayEnabled=false;
        transferTaxes.marketingTax = 0;
    }
    
    function _taxCalc(address _from, address _to, uint256 _amount) internal returns (uint256) {
        if (whitelisted[_from] || whitelisted[_to]) {
            return _amount;
        }

        uint256 totalTax = transferTaxes.marketingTax;
        if (launchTax) {
            if (block.number > startTradingBlock + 35) {
                buyTaxes.marketingTax = 3;
                sellTaxes.marketingTax = 5;
                launchTax = false;

            } else if (block.number <= startTradingBlock + 5) {
                buyTaxes.marketingTax = 20;
                sellTaxes.marketingTax = 20;
            } else if (block.number <= startTradingBlock + 20) {
                buyTaxes.marketingTax = 10;
                sellTaxes.marketingTax = 20;
            } else if (block.number <= startTradingBlock + 35) {
                buyTaxes.marketingTax = 5;
                sellTaxes.marketingTax = 20;
            }
        }
        if (_to == pairAddress) {
            totalTax = sellTaxes.marketingTax;
        } else if (_from == pairAddress) {
            totalTax = buyTaxes.marketingTax;
        }

        uint256 tax = 0;
        if (totalTax > 0) {
            tax = (_amount * totalTax) / 100;
            super._transfer(_from, address(this), tax);
        }
        return (_amount - tax);
    }

    function _transfer(address _from, address _to, uint256 _amount) internal virtual override {

        if (transferDelayEnabled) {
            if (_to != address(pairAddress) && _to != address(pairAddress)) {
                require(_holderLastTransferTimestamp[tx.origin] < block.number, "Only one transfer per block allowed.");
                _holderLastTransferTimestamp[tx.origin] = block.number;
            }
        }   

        require(_from != address(0), "transfer from address zero");
        require(_to != address(0), "transfer to address zero");
        require(_amount > 0, "Transfer amount must be greater than zero");

        uint256 maxWalletAmount = _totalSupply * maxWalletPercentage / 100;

        if (!whitelisted[_from] && !whitelisted[_to] && _to != address(0) && _to != address(this) && _to != pairAddress) {
            require(balanceOf(_to) + _amount <= maxWalletAmount, "Exceeds maximum wallet amount");
        }

        uint256 toTransfer = _taxCalc(_from, _to, _amount);

        bool canSwap = balanceOf(address(this)) >= swapTokensAtAmount;
        if (!whitelisted[_from] && !whitelisted[_to]) {
            require(tradingEnabled, "Trading not active");
            if (pairAddress == _to && swapAndLiquifyEnabled && canSwap && !isSwapping) {
                internalSwap();
            }
        }
        super._transfer(_from, _to, toTransfer);
    }

    function internalSwap() internal {
        isSwapping = true;
        uint256 taxAmount = balanceOf(address(this)); 
        if (taxAmount == 0) {
            return;
        }
        swapToETH(balanceOf(address(this)));
       (bool success, ) = marketingWallet.call{value: address(this).balance}("");
        require(success , "Transfer failed.");
        isSwapping = false;
    }  

    function swapToETH(uint256 _amount) internal {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapRouter.WETH();
        _approve(address(this), address(uniswapRouter), _amount);
        uniswapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            _amount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }
    
    receive() external payable {}
}