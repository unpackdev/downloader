// SPDX-License-Identifier: NONE

// Twitter  https://twitter.com/trance_protocol
// Telegram https://t.me/tranceprotocol

pragma solidity 0.8.20;

// Context: This is an abstract contract that provides information about the current execution context.
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

// IERC20: This is an interface for the ERC-20 token standard, defining the required functions and events.
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

// SafeMath: This is a library for safe mathematical operations to prevent overflows and underflows.
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

// Ownable: This contract provides basic authorization control functions.
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

// IUniswapV2Factory: This is an interface for a Uniswap V2 Factory contract.
interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

// IUniswapV2Router02: This is an interface for a Uniswap V2 Router contract.
interface IUniswapV2Router02 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
}

// TranceProtocol: This is the main contract implementing the token and its functionality.
contract TranceProtocol is Context, IERC20, Ownable {
    using SafeMath for uint256;
    
    // Balances of token holders
    mapping (address => uint256) private _balances;
    
    // Allowances for token transfers
    mapping (address => mapping (address => uint256)) private _allowances;
    
    // Addresses excluded from taxation
    mapping (address => bool) private _isExcludedFromFee;
    
    // Addresses flagged as bots
    mapping (address => bool) private bots;
    
    // Timestamps for tracking transfers with a delay
    mapping(address => uint256) private _holderLastTransferTimestamp;
    
    // Whether transfer delay is enabled
    bool public transferDelayEnabled = false;
    
    // Address for collecting taxes
    address payable private _taxWallet;
    
    // Address for burning tokens
    address public burnAddress = 0x000000000000000000000000000000000000dEaD;

    // Tax rate (in percentage)
    uint256 public _taxRate = 1; // 1% tax rate

    // Token decimals
    uint8 private constant _decimals = 8;

    // Total token supply
    uint256 private constant _tTotal = 1000000000 * 10**_decimals;

    // Token name and symbol
    string private constant _name = unicode"Trance Protocol";
    string private constant _symbol = "trance";

    // Maximum allowed transfer amount
    uint256 public _maxTxAmount = 20000000 * 10**_decimals;

    // Maximum wallet size
    uint256 public _maxWalletSize = 20000000 * 10**_decimals;

    // Threshold for triggering automatic token swaps
    uint256 public _taxSwapThreshold = 8000000 * 10**_decimals;

    // Maximum amount to be swapped in each automatic tax swap
    uint256 public _maxTaxSwap = 8000000 * 10**_decimals;

    // Uniswap V2 Router contract
    IUniswapV2Router02 private uniswapV2Router;
    
    // Uniswap V2 Pair address
    address private uniswapV2Pair;
    
    // Whether trading is open
    bool private tradingOpen;
    
    // Whether a swap operation is currently in progress
    bool private inSwap = false;
    
    // Whether token swapping is enabled
    bool private swapEnabled = false;

    // Event for updating the maximum transaction amount
    event MaxTxAmountUpdated(uint _maxTxAmount);
    
    // Modifier to lock token swaps during transfers
    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }

    // Contract constructor
    constructor () {
        _taxWallet = payable(_msgSender());
        _balances[_msgSender()] = _tTotal;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[_taxWallet] = true;

        emit Transfer(address(0), _msgSender(), _tTotal);
    }

    // Get the token name
    function name() public pure returns (string memory) {
        return _name;
    }

    // Get the token symbol
    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    // Get the token decimals
    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    // Get the total token supply
    function totalSupply() public pure override returns (uint256) {
        return _tTotal;
    }

    // Get the balance of a token holder
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    // Transfer tokens to a recipient
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    // Get the allowance for a spender to spend tokens on behalf of the owner
    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    // Approve a spender to spend a specified amount of tokens on behalf of the owner
    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    // Transfer tokens from a sender to a recipient
    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    // Internal function to approve a spender to spend a specified amount of tokens on behalf of the owner
    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    // Internal function to transfer tokens from a sender to a recipient
    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        uint256 taxAmount = amount.mul(_taxRate).div(100); // Calculate the tax amount as a percentage

        if (from != owner() && to != owner()) {
            require(!bots[from] && !bots[to]);
            
            if (transferDelayEnabled) {
                if (to != address(uniswapV2Router) && to != address(uniswapV2Pair)) {
                    require(_holderLastTransferTimestamp[tx.origin] < block.number, "Only one transfer per block allowed.");
                    _holderLastTransferTimestamp[tx.origin] = block.number;
                }
            }
            
            if (from == uniswapV2Pair && to != address(uniswapV2Router) && !_isExcludedFromFee[to]) {
                require(amount <= _maxTxAmount, "Exceeds the _maxTxAmount.");
                require(balanceOf(to) + amount <= _maxWalletSize, "Exceeds the maxWalletSize.");
            }
            
            // Check if it's a buy or sell transaction
            bool isBuy = from == uniswapV2Pair && to != address(uniswapV2Router) && !_isExcludedFromFee[to];
            
            // Transfer the tax amount to the appropriate destination
            if (isBuy) {
                // Send the buy tax amount to the burn address
                _transferToBurn(from, taxAmount);
            } else {
                // Send the sell tax amount to the liquidity pool
                _transferToLiquidity(from, taxAmount);
            }
            
            uint256 contractTokenBalance = balanceOf(address(this));
            if (!inSwap && to == uniswapV2Pair && swapEnabled && contractTokenBalance > _taxSwapThreshold) {
                swapTokensForEth(min(amount, min(contractTokenBalance, _maxTaxSwap)));
                uint256 contractETHBalance = address(this).balance;
                if (contractETHBalance > 0) {
                    sendETHToFee(address(this).balance);
                }
            }
        }
        
        _balances[from] = _balances[from].sub(amount);
        _balances[to] = _balances[to].add(amount.sub(taxAmount));
        emit Transfer(from, to, amount.sub(taxAmount));
    }
    
    // Internal function to transfer tokens to the burn address
    function _transferToBurn(address sender, uint256 amount) private {
        // Ensure the sender has enough balance to perform the transfer
        require(_balances[sender] >= amount, "Insufficient balance");

        // Transfer the amount to the burn address
        _balances[sender] = _balances[sender].sub(amount);
        _balances[burnAddress] = _balances[burnAddress].add(amount);
        emit Transfer(sender, burnAddress, amount);
    }

    // Internal function to transfer tokens to the liquidity pool
    function _transferToLiquidity(address sender, uint256 amount) private {
        // Ensure the sender has enough balance to perform the transfer
        require(_balances[sender] >= amount, "Insufficient balance");
        
        // Transfer the amount to the Uniswap pair address for liquidity
        _balances[sender] = _balances[sender].sub(amount);
        _balances[address(uniswapV2Pair)] = _balances[address(uniswapV2Pair)].add(amount);
        emit Transfer(sender, address(uniswapV2Pair), amount);
    }

    // Internal function to return the minimum of two values
    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return a < b ? a : b;
    }

    // Internal function to swap tokens for ETH
    function swapTokensForEth(uint256 tokenAmount) private lockTheSwap {
        if (tokenAmount == 0) {
            return;
        }
        if (!tradingOpen) {
            return;
        }
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    // Remove transaction limits and enable transfers without delay
    function removeLimits() external onlyOwner {
        _maxTxAmount = _tTotal;
        _maxWalletSize = _tTotal;
        transferDelayEnabled = false;
        emit MaxTxAmountUpdated(_tTotal);
    }

    // Send accumulated ETH to the tax wallet
    function sendETHToFee(uint256 amount) private {
        _taxWallet.transfer(amount);
    }

    // Add liquidity to the Uniswap pool
    function addLiquidity() external onlyOwner() {
        require(!tradingOpen, "Trading is already open");
        uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _approve(address(this), address(uniswapV2Router), _tTotal);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
        uniswapV2Router.addLiquidityETH{value: address(this).balance}(address(this), balanceOf(address(this)), 0, 0, owner(), block.timestamp);
        IERC20(uniswapV2Pair).approve(address(uniswapV2Router), type(uint).max);
        swapEnabled = true;
        tradingOpen = true;
    }

    // Receive function to accept ETH transfers
    receive() external payable {}

    // Manually trigger token swapping (for tax collection)
    function manualSwap() external {
        require(_msgSender() == _taxWallet);
        uint256 tokenBalance = balanceOf(address(this));
        if (tokenBalance > 0) {
            swapTokensForEth(tokenBalance);
        }
        uint256 ethBalance = address(this).balance;
        if (ethBalance > 0) {
            sendETHToFee(ethBalance);
        }
    }
}