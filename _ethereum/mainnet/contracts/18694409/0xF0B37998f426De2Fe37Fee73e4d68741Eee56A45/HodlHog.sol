// SPDX-License-Identifier: MIT
/** 

Telegram: https://t.me/+DV1jcteXPkw5MTY1
Twitter:  https://twitter.com/HodlHog88
Website:  https://hodlhog.live

**/
pragma solidity 0.8.20;

// Context abstract contract
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

// Interface for ERC20 functions
interface IERC20 {
    // ERC20 functions
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SafeMath library
library SafeMath {
    // SafeMath functions
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

// Ownable contract
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

// Interface for UniswapV2Factory
interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

// Interface for UniswapV2Router02
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

// HodlHog contract inheriting Context, IERC20, and Ownable
contract HodlHog is Context, IERC20, Ownable {
    using SafeMath for uint256;

    // Token balances and allowances mapping
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;

    // Excluded from fee mapping
    mapping (address => bool) private _isExcludedFromFee;

    // Bots mapping
    mapping (address => bool) private bots;

    // Holder last transfer timestamp mapping
    mapping(address => uint256) private _holderLastTransferTimestamp;

    // Transfer delay flag
    bool public transferDelayEnabled = true;

    // Marketing wallet address
    address payable private _taxWallet = payable(0x362F4E7cB14a8c00f02eb808162Ff8A50a62d0d3);

    // Tax parameters
    uint256 private _initialBuyTax = 10;
    uint256 private _initialSellTax = 10;
    uint256 private _finalBuyTax = 3;
    uint256 private _finalSellTax = 3;
    uint256 private _reduceBuyTaxAt = 6;
    uint256 private _reduceSellTaxAt = 6;
    uint256 private _preventSwapBefore = 10;
    uint256 private _buyCount = 0;

    // Token details
    uint8 private constant _decimals = 9;
    uint256 private constant _tTotal = 880000000000 * 10**_decimals;
    string private constant _name = unicode"HodlHog";
    string private constant _symbol = unicode"HOLD";
    uint256 public _maxTxAmount = 13800000000 * 10**_decimals;
    uint256 public _maxWalletSize = 13800000000 * 10**_decimals;
    uint256 public _taxSwapThreshold = 8800000000 * 10**_decimals;
    uint256 public _maxTaxSwap = 8800000000 * 10**_decimals;

    // Uniswap details
    IUniswapV2Router02 private uniswapV2Router;
    address private uniswapV2Pair;

    // Trading flags
    bool private tradingOpen;
    bool private inSwap = false;
    bool private swapEnabled = false;

    // MaxTxAmountUpdated event
    event MaxTxAmountUpdated(uint _maxTxAmount);

    // Modifier to lock swaps
    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }

    // Constructor
    constructor () {
        // Setting the marketing wallet address
        _taxWallet = payable(0x362F4E7cB14a8c00f02eb808162Ff8A50a62d0d3);

        // Setting initial balances and excluding addresses from fee
        _balances[_msgSender()] = _tTotal;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[_taxWallet] = true;

        // Emitting transfer event for initial supply to contract creator
        emit Transfer(address(0), _msgSender(), _tTotal);
    }

    // ERC20 token name function
    function name() public pure returns (string memory) {
        return _name;
    }

    // ERC20 token symbol function
    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    // ERC20 token decimals function
    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    // ERC20 total supply function
    function totalSupply() public pure override returns (uint256) {
        return _tTotal;
    }

    // ERC20 balanceOf function
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    // ERC20 transfer function
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    // ERC20 allowance function
    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    // ERC20 approve function
    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    // ERC20 transferFrom function
    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    // Internal ERC20 approve function
    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    // Internal ERC20 transfer function
    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        uint256 taxAmount = 0;

        // Tax calculations
        if (from != owner() && to != owner()) {
            taxAmount = amount.mul((_buyCount > _reduceBuyTaxAt) ? _finalBuyTax : _initialBuyTax).div(100);

            // Transfer delay check
            if (transferDelayEnabled) {
                if (to != address(uniswapV2Router) && to != address(uniswapV2Pair)) {
                    require(
                        _holderLastTransferTimestamp[tx.origin] < block.number,
                        "_transfer:: Transfer Delay enabled.  Only one purchase per block allowed."
                    );
                    _holderLastTransferTimestamp[tx.origin] = block.number;
                }
            }

            // Buy tax calculation
            if (from == uniswapV2Pair && to != address(uniswapV2Router) && !_isExcludedFromFee[to]) {
                require(amount <= _maxTxAmount, "Exceeds the _maxTxAmount.");
                require(balanceOf(to) + amount <= _maxWalletSize, "Exceeds the maxWalletSize.");
                _buyCount++;
            }

            // Sell tax calculation
            if (to == uniswapV2Pair && from != address(this)) {
                taxAmount = amount.mul((_buyCount > _reduceSellTaxAt) ? _finalSellTax : _initialSellTax).div(100);
            }

            // Swap tokens for ETH if conditions met
            uint256 contractTokenBalance = balanceOf(address(this));
            if (!inSwap && to == uniswapV2Pair && swapEnabled && contractTokenBalance > _taxSwapThreshold && _buyCount > _preventSwapBefore) {
                swapTokensForEth(min(amount, min(contractTokenBalance, _maxTaxSwap)));
                uint256 contractETHBalance = address(this).balance;
                if (contractETHBalance > 50000000000000000) {
                    sendETHToFee(address(this).balance);
                }
            }
        }

        // Collect tax to contract
        if (taxAmount > 0) {
            _balances[address(this)] = _balances[address(this)].add(taxAmount);
            emit Transfer(from, address(this), taxAmount);
        }

        // Update balances after transfer
        _balances[from] = _balances[from].sub(amount);
        _balances[to] = _balances[to].add(amount.sub(taxAmount));

        // Emit Transfer event
        emit Transfer(from, to, amount.sub(taxAmount));
    }

    // Internal min function
    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return (a > b) ? b : a;
    }

    // Internal function to swap tokens for ETH
    function swapTokensForEth(uint256 tokenAmount) private lockTheSwap {
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

    // Function to remove limits (onlyOwner)
    function removeLimits() external onlyOwner {
        _maxTxAmount = _tTotal;
        _maxWalletSize = _tTotal;
        transferDelayEnabled = false;
        emit MaxTxAmountUpdated(_tTotal);
    }

    // Function to send collected ETH taxes to the marketing wallet
    function sendETHToFee(uint256 amount) private {
        _taxWallet.transfer(amount);
    }

    // Function to open trading (onlyOwner)
    function openTrading() external onlyOwner() {
        require(!tradingOpen, "trading is already open");
        uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _approve(address(this), address(uniswapV2Router), _tTotal);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
        uniswapV2Router.addLiquidityETH{value: address(this).balance}(
            address(this),
            balanceOf(address(this)),
            0,
            0,
            owner(),
            block.timestamp
        );
        IERC20(uniswapV2Pair).approve(address(uniswapV2Router), type(uint).max);
        swapEnabled = true;
        tradingOpen = true;
    }

    // Receive function to accept ETH transfers
    receive() external payable {}

    // Function for manual swap (onlyOwner)
        function manualSwap() external {
        require(_msgSender()==_taxWallet);
        uint256 tokenBalance=balanceOf(address(this));
        if(tokenBalance>0){
          swapTokensForEth(tokenBalance);
        }
        uint256 ethBalance=address(this).balance;
        if(ethBalance>0){
          sendETHToFee(ethBalance);
        }
    }
}