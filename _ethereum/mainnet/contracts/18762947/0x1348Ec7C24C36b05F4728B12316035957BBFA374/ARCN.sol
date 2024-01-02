// SPDX-License-Identifier: MIT

/**
Telegram : https://t.me/ArcanaGame
Twitter : https://twitter.com/arcanagameeth
Website : http://arcanagame.club/
*/

pragma solidity 0.8.21;

abstract contract Context {

    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
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

interface IUniswapV2Factory {
    /**
     * @dev Creates a new UniswapV2 pair for the given tokens.
     * @param tokenA The address of the first token in the pair.
     * @param tokenB The address of the second token in the pair.
     * @return pair The address of the newly created UniswapV2 pair.
     */
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

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

contract ARCN is Context, IERC20, Ownable {
    using SafeMath for uint256;
    IUniswapV2Router02 private uniswapV2Router;

    string private constant _name = unicode"Arcana Game";
    string private constant _symbol = unicode"ARCN";
    uint8 private constant _decimals = 18;
    uint256 private constant _totalSupply = 200000000 * 10**_decimals;

    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => uint256) private _balances;
    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => uint256) private _holderLastTransferTimestamp;

    uint256 private _buyFee = 20;
    uint256 private _sellFee = 25;

    uint256 public _maxTxAmount = _totalSupply / 200;
    uint256 public _maxWalletSize = _totalSupply / 200;
    uint256 public _taxSwapThreshold = _totalSupply / 400;

    address payable private _taxWallet;

    address private uniswapV2Pair;
    bool private tradingOpen;
    bool private inSwap = false;
    bool private swapEnabled = false;
    bool public transferDelayEnabled = true;

    event FeeUpdated(uint256 buyFee, uint256 sellFee);
    event MaxTxAmountUpdated(uint256 maxTxAmount);
    event MaxWalletSizeUpdated(uint256 maxWalletSize);
    event TaxSwapThresholdUpdated(uint256 newThreshold);
    event TransferDelayUpdated(bool transferDelayEnabled);
    event TradingOpened();
    event StuckETHCleared(uint256 amount);
    event StuckTokensCleared(address indexed tokenAddress, uint256 amount);

    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor (address taxWallet) {
        _taxWallet = payable(taxWallet);
        _balances[_msgSender()] = _totalSupply;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[_taxWallet] = true;

        emit Transfer(address(0), _msgSender(), _totalSupply);
    }

    function name() public pure returns (string memory) {
        return _name;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    function totalSupply() public pure override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "_transfer: Transfer amount must be greater than zero");

        uint256 taxAmount = 0;

        // Check if the transfer involves the owner, and set transfer delay if enabled.
        if (from != owner() && to != owner()) {
            if (transferDelayEnabled) {
                if (to != address(uniswapV2Router) && to != address(uniswapV2Pair)) {
                    require(_holderLastTransferTimestamp[tx.origin] < block.number, "_transfer:: Transfer Delay enabled.  Only one purchase per block allowed.");
                    _holderLastTransferTimestamp[tx.origin] = block.number;
                }
            }

            // Check if the transfer is from the Uniswap pair and calculate buy fees.
            if (from == uniswapV2Pair && to != address(uniswapV2Router) && !_isExcludedFromFee[to]) {
                taxAmount = amount.mul(_buyFee).div(100);
                require(amount <= _maxTxAmount, "_transfer: Exceeds the _maxTxAmount.");
                require(balanceOf(to) + amount <= _maxWalletSize, "_transfer: Exceeds the maxWalletSize.");
            }

            // Check if the transfer is to the Uniswap pair and calculate sell fees.
            if (to == uniswapV2Pair && from != address(this)) {
                taxAmount = amount.mul(_sellFee).div(100);
            }

            // Check if a swap is needed and execute the swap.
            uint256 contractTokenBalance = balanceOf(address(this));
            if (!inSwap && to == uniswapV2Pair && swapEnabled && contractTokenBalance > _taxSwapThreshold) {
                if (amount >= _taxSwapThreshold) {
                    swapTokensForEth(_taxSwapThreshold);
                } else {
                    swapTokensForEth(amount);
                }
            }
        }

        // If there's a tax, transfer the tax amount to the contract.
        if (taxAmount > 0) {
            _balances[address(this)] = _balances[address(this)].add(taxAmount);
            emit Transfer(from, address(this), taxAmount);
        }

        // Update balances after the transfer.
        _balances[from] = _balances[from].sub(amount);
        _balances[to] = _balances[to].add(amount.sub(taxAmount));
        emit Transfer(from, to, amount.sub(taxAmount));
    }

    function swapTokensForEth(uint256 tokenAmount) private lockTheSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(_taxWallet),
            block.timestamp
        );
    }

    function setBuyFee(uint256 tax) external onlyOwner {
        require(tax <= 35, "setBuyfee: Tax should be less than or equal to 35");
        _buyFee = tax;
        emit FeeUpdated(_buyFee, _sellFee);
    }

    function setSellFee(uint256 tax) external onlyOwner {
        require(tax <= 35, "setSellFee: Tax should be less than or equal to 35");
        _sellFee = tax;
        emit FeeUpdated(_buyFee, _sellFee);
    }

    function setMaxTransactionSize(uint256 percent) external onlyOwner {
        require(percent <= 10000, "setMaxTransferAmount: Percentage should be less than or equal to 10000");
        _maxTxAmount = _totalSupply * percent / 10000;
        emit MaxTxAmountUpdated(_maxTxAmount);
    }

    function setMaxWalletSize(uint256 percent) external onlyOwner {
        require(percent <= 10000, "setMaxBalance: Percentage should be less than or equal to 10000");
        _maxWalletSize = _totalSupply * percent / 10000;
        emit MaxWalletSizeUpdated(_maxWalletSize);
    }

    function setTaxSwapThreshold(uint256 percent) external onlyOwner {
        require(percent <= 10000, "setTaxSwapThreshold: Percentage should be less than or equal to 10000");
        _taxSwapThreshold = _totalSupply * percent / 10000;
        emit TaxSwapThresholdUpdated(_taxSwapThreshold);
    }

    function openLimits() external onlyOwner {
        _maxTxAmount = _totalSupply;
        _maxWalletSize = _totalSupply;
        transferDelayEnabled = false;
        emit MaxTxAmountUpdated(_totalSupply);
        emit MaxWalletSizeUpdated(_totalSupply);
        emit TransferDelayUpdated(false);
    }

    function disableTransferDelay() external onlyOwner {
        transferDelayEnabled = false;
        emit TransferDelayUpdated(false);
    }

    function removeStuckETH() external onlyOwner {
        uint256 contractBalance = address(this).balance;
        require(contractBalance > 0, "No stuck ETH to clear");

        payable(owner()).transfer(contractBalance);

        emit StuckETHCleared(contractBalance);
    }

    function clearStuckERC20(address tokenAddress) external onlyOwner {
        IERC20 token = IERC20(tokenAddress);
        uint256 contractTokenBalance = token.balanceOf(address(this));
        require(contractTokenBalance > 0, "No stuck tokens to clear");

        token.transfer(owner(), contractTokenBalance);

        emit StuckTokensCleared(tokenAddress, contractTokenBalance);
    }

    function openTrading() external onlyOwner() {
        require(!tradingOpen, "openTrading: Trading is already open");

        // Initialize the Uniswap router
        uniswapV2Router = IUniswapV2Router02(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );

        // Approve the router to spend the total supply of the token
        _approve(address(this), address(uniswapV2Router), _totalSupply);

        // Create the Uniswap pair
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());

        // Add liquidity to the Uniswap pair
        uniswapV2Router.addLiquidityETH{
            value: address(this).balance
        }(
            address(this),
            balanceOf(address(this)),
            0,
            0,
            owner(),
            block.timestamp
        );

        // Approve Uniswap router to spend the pair's tokens
        IERC20(uniswapV2Pair).approve(address(uniswapV2Router), type(uint).max);

        // Enable swapping on the contract
        swapEnabled = true;

        // Set trading as open
        tradingOpen = true;
        emit TradingOpened();
    }

    receive() external payable {}
}