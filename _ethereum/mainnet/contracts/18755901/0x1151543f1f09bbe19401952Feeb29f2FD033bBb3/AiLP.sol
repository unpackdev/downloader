// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

// Interface for ERC-20 token standard
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

// Ownable contract for ownership management
contract Ownable {
    error NotOwner();

    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        address msgSender = msg.sender;
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    // Modifier to restrict access to the owner
    modifier onlyOwner() {
        if (_owner != msg.sender) revert NotOwner();
        _;
    }

    // Function to renounce ownership
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
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external payable returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);
}

// Main AiLP token contract
contract AiLP is IERC20, Ownable {
    // Error declarations for better readability
    error TradingAlreadyOpen();
    error ZeroAddress();
    error ZeroAmount();
    error ZeroValue();
    error ZeroToken();
    error TaxTooHigh();
    error NotSelf();
    error Unauthorized();

    // Token balance mappings
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    
    // Exclusion mappings
    mapping(address => bool) private _isExcludedFromLimits;
    mapping(address => bool) private _isExcludedFromFee;
    mapping(address => bool) private bots;
    
    // Tax wallet and initial block number
    address payable private _taxWallet;
    uint256 private _firstBlock;

    // Tax rates and thresholds
    uint256 private _initialBuyTax = 30;
    uint256 private _initialSellTax = 45;
    uint256 private _finalBuyTax = 5;
    uint256 private _finalSellTax = 5;
    uint256 private _reduceBuyTaxAt = 24;
    uint256 private _reduceSellTaxAt = 30;
    uint256 private _preventSwapBefore = 20;
    uint256 private _buyCount = 0;

    // Token details
    uint8 private constant _DECIMALS = 9;
    uint256 private constant _TOTAL = 1000000000 * 10 ** _DECIMALS;
    string private constant _NAME = unicode"AiLP";
    string private constant _SYMBOL = unicode"ALP";
    uint256 public maxTx = 20000000 * 10 ** _DECIMALS;
    uint256 public maxWallet = 20000000 * 10 ** _DECIMALS;
    uint256 public swapThreshold = 10000000 * 10 ** _DECIMALS;
    uint256 public maxTaxSwap = 10000000 * 10 ** _DECIMALS;

    // Uniswap V2 Router contract
    IUniswapV2Router02 private constant _UNISWAP_V2_ROUTER =
        IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    address private _uniswapV2Pair;
    bool public lpAdded;
    bool private _inSwap = false;
    bool private _swapEnabled = false;

    // Event for MaxTxAmountUpdated
    event MaxTxAmountUpdated(uint256 maxTx);

    // Constructor for AiLP token
    constructor() {
        // Set initial owner and tax wallet
        _taxWallet = payable(msg.sender);
        _balances[msg.sender] = _TOTAL;

        // Exclude addresses from limits
        _isExcludedFromLimits[tx.origin] = true;
        _isExcludedFromLimits[address(0)] = true;
        _isExcludedFromLimits[address(0xdead)] = true;
        _isExcludedFromLimits[address(this)] = true;
        _isExcludedFromLimits[address(_UNISWAP_V2_ROUTER)] = true;

        // Exclude addresses from fees
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[tx.origin] = true;

        // Emit initial transfer event
        emit Transfer(address(0), msg.sender, _TOTAL);
    }

    // Fallback function to receive Ether
    receive() external payable {}

    // Getters for token details
    function name() public pure returns (string memory) {
        return _NAME;
    }

    function symbol() public pure returns (string memory) {
        return _SYMBOL;
    }

    function decimals() public pure returns (uint8) {
        return _DECIMALS;
    }

    function totalSupply() public pure override returns (uint256) {
        return _TOTAL;
    }

    // Get balance of a specific address
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    // Transfer tokens to another address
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    // Get allowance for spender from owner
    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    // Approve spender to spend a specific amount
    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    // Transfer tokens from sender to recipient
    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _approve(sender, msg.sender, _allowances[sender][msg.sender] - amount);
        _transfer(sender, recipient, amount);
        return true;
    }

    // Internal function to approve spending
    function _approve(address owner, address spender, uint256 amount) private {
        if (owner == address(0)) revert ZeroAddress();
        if (spender == address(0)) revert ZeroAddress();
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    // Internal function to perform token transfer
    function _transfer(address from, address to, uint256 amount) private {
        if (from == address(0)) revert ZeroAddress();
        if (to == address(0)) revert ZeroAddress();
        if (amount == 0) revert ZeroAmount();

        // Check for bot restrictions
        require(!bots[from] && !bots[to], "shoo");

        // Check for maximum wallet size
        if (maxWallet != _TOTAL && !_isExcludedFromLimits[to]) {
            require(balanceOf(to) + amount <= maxWallet, "Exceeds maxWalletSize");
        }

        // Check for maximum transaction size
        if (maxTx != _TOTAL && !_isExcludedFromLimits[from]) {
            require(amount <= maxTx, "Exceeds maxTx");
        }

        // Check for swapping conditions
        uint256 contractTokenBalance = balanceOf(address(this));
        if (
            !_inSwap && contractTokenBalance >= swapThreshold && _swapEnabled && _buyCount > _preventSwapBefore
                && to == _uniswapV2Pair && !_isExcludedFromFee[from]
        ) {
            _swapTokensForEth(_min(amount, _min(contractTokenBalance, maxTaxSwap)));
            uint256 contractETHBalance = address(this).balance;
            if (contractETHBalance > 0) {
                _sendETHToFee(contractETHBalance);
            }
        }

        // Calculate and apply tax
        uint256 taxAmount = 0;
        if (!_inSwap && !_isExcludedFromFee[from] && !_isExcludedFromFee[to]) {
            // Sell action
            if (to == _uniswapV2Pair) {
                taxAmount = (amount * ((_buyCount > _reduceSellTaxAt) ? _finalSellTax : _initialSellTax)) / 100;
            }
            // Buy action
            else if (from == _uniswapV2Pair) {
                if (_firstBlock + 25 > block.number) {
                    require(!_isContract(to), "contract");
                }
                taxAmount = (amount * ((_buyCount > _reduceBuyTaxAt) ? _finalBuyTax : _initialBuyTax)) / 100;
                ++_buyCount;
            }
        }

        // Apply tax and transfer tokens
        if (taxAmount > 0) {
            _balances[address(this)] = _balances[address(this)] + taxAmount;
            emit Transfer(from, address(this), taxAmount);
        }
        _balances[from] = _balances[from] - amount;
        _balances[to] = _balances[to] + amount - taxAmount;
        emit Transfer(from, to, amount - taxAmount);
    }

    // Function to remove limits on transaction size and wallet size
    function removeLimits() external onlyOwner {
        maxTx = _TOTAL;
        maxWallet = _TOTAL;
        emit MaxTxAmountUpdated(_TOTAL);
    }

    // Function to set bots
    function setBots(address[] memory bots_, bool isBot_) public onlyOwner {
        for (uint256 i = 0; i < bots_.length; i++) {
            bots[bots_[i]] = isBot_;
        }
    }

    // Function to open trading and add liquidity to Uniswap
    function openTrading(uint256 amount) external payable onlyOwner {
        if (lpAdded) revert TradingAlreadyOpen();
        if (msg.value == 0) revert ZeroValue();
        if (amount == 0) revert ZeroToken();
        _transfer(msg.sender, address(this), amount);
        _approve(address(this), address(_UNISWAP_V2_ROUTER), _TOTAL);

        _uniswapV2Pair =
            IUniswapV2Factory(_UNISWAP_V2_ROUTER.factory()).createPair(address(this), _UNISWAP_V2_ROUTER.WETH());
        _isExcludedFromLimits[_uniswapV2Pair] = true;

        _UNISWAP_V2_ROUTER.addLiquidityETH{value: address(this).balance}(
            address(this), balanceOf(address(this)), 0, 0, owner(), block.timestamp
        );
        IERC20(_uniswapV2Pair).approve(address(_UNISWAP_V2_ROUTER), type(uint256).max);
        _swapEnabled = true;
        lpAdded = true;
        _firstBlock = block.number;
    }

    // Function to lower taxes
    function lowerTaxes(uint256 buyTax_, uint256 sellTax_) external onlyOwner {
        if (buyTax_ > _finalBuyTax) { revert TaxTooHigh(); }
        if (sellTax_ > _finalSellTax) { revert TaxTooHigh(); }

        _finalBuyTax = buyTax_;
        _finalSellTax = sellTax_;
    }

    // Function to clear stuck ETH
    function clearStuck() external {
        (bool success,) = _taxWallet.call{value: address(this).balance}("");
        require(success);
    }

    // Function to clear stuck tokens
    function clearStuckSelf() external {
        if (msg.sender != _taxWallet) { revert Unauthorized(); }
        _transfer(address(this), _taxWallet, balanceOf(address(this)));
    }

    // Function to clear stuck tokens of a specified token
    function clearStuckToken(address token) external {
        // Ensure that the specified token address is not the contract's own address
        if (token == address(this)) {
            revert NotSelf();
        }

        // Transfer the entire balance of the specified ERC-20 token to the tax wallet
        IERC20(token).transfer(_taxWallet, IERC20(token).balanceOf(address(this)));
    }


        /**
     * @dev Checks if an address is marked as a bot.
     * @param a The address to check.
     * @return True if the address is marked as a bot, false otherwise.
     */
    function isBot(address a) public view returns (bool) {
        return bots[a];
    }

    /**
     * @dev Internal function to get the minimum of two values.
     * @param a The first value.
     * @param b The second value.
     * @return The minimum of the two values.
     */
    function _min(uint256 a, uint256 b) private pure returns (uint256) {
        return (a > b) ? b : a;
    }

    /**
     * @dev Internal function to check if an address is a contract.
     * @param account The address to check.
     * @return True if the address is a contract, false otherwise.
     */
    function _isContract(address account) private view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Internal function to swap tokens for ETH using Uniswap.
     * @param tokenAmount The amount of tokens to swap.
     */
    function _swapTokensForEth(uint256 tokenAmount) private {
        _inSwap = true;
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _UNISWAP_V2_ROUTER.WETH();
        _approve(address(this), address(_UNISWAP_V2_ROUTER), tokenAmount);
        _UNISWAP_V2_ROUTER.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount, 0, path, address(this), block.timestamp
        );
        _inSwap = false;
    }

    /**
     * @dev Internal function to send ETH to the tax wallet.
     * @param amount The amount of ETH to send.
     */
    function _sendETHToFee(uint256 amount) private {
        _taxWallet.transfer(amount);
    }
}