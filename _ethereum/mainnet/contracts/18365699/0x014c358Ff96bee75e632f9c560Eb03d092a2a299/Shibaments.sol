/**
Choose your path, forge your destiny.

Website: https://www.shibaments.art
Telegram: https://t.me/sbmt_eth
Twitter: https://twitter.com/sbmt_eth
*/ 

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;


abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

interface IUniswapV2Router02 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

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
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

interface IUniswapFactory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
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
interface IERC20MetaData is IERC20 {

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
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

contract ERC20 is Context, IERC20, IERC20MetaData {
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

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

contract Shibaments is ERC20, Ownable {
    using SafeMath for uint256;

    IUniswapV2Router02 public immutable DEX_ROUTER;
    address public immutable DEX_PAIR;
    address public routerAddy = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    mapping(address => bool) private _isExcludedFromFees;
    mapping(address => bool) private _isExcludedFromMaxTx;
    mapping(address => bool) private _isExcludedFromMaxWallet;
    
    mapping(address => uint256) private _holderLastTimestamp;
    bool public hasDelayOnTransfer = true;
    uint256 private initialBlock;
    uint256 private deadBlocks;
    mapping(address => bool) public ammPairs;
    
    bool private swapping;
    uint256 public maxTxAmount;
    uint256 public swapTokensAtAmount;
    uint256 public maxWallet;

    uint256 public totalSellFee;
    uint256 public feeMarketingSell;
    uint256 public feeLiquiditySell;
    uint256 public feeDevSell;

    uint256 public totalBuyFee;
    uint256 public feeMarketingBuy;
    uint256 public feeLiquidityBuy;
    uint256 public feeBuyDev;

    uint256 public marketingTokens;
    uint256 public lpTokens;
    uint256 public devTokens;
    
    address public marketingWallet;
    address public devAddy;
    address public lpReceiver;

    bool public hasLimits = true;
    bool public tradeEnabled = false;
    bool public swapEnabled = false;
    
    event ExcludeFromFees(address indexed account, bool isExcluded);

    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);

    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiquidity
    );

    modifier onlyOperation {
      require(isExcludedFromTax(msg.sender));_;
    }

    constructor() ERC20("Shibaments", "SB") {
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(routerAddy); 

        excludeFromMaxTransaction(address(_uniswapV2Router), true);
        DEX_ROUTER = _uniswapV2Router;

        DEX_PAIR = IUniswapFactory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
        excludeFromMaxTransaction(address(DEX_PAIR), true);
        _setAmmPair(address(DEX_PAIR), true);

        // launch buy fees
        uint256 _buyMarketingFee = 15;
        uint256 _buyLiquidityFee = 0;
        uint256 _buyDevFee = 0;
        
        // launch sell fees
        uint256 _sellMarketingFee = 15;
        uint256 _sellLiquidityFee = 0;
        uint256 _sellDevFee = 0;

        uint256 totalSupply = 1_000_000_000 * 1e18;

        maxTxAmount = 15_000_000 * 1e18;
        maxWallet = 15_000_000 * 1e18;
        swapTokensAtAmount = (totalSupply * 1) / 10000;

        feeMarketingBuy = _buyMarketingFee;
        feeLiquidityBuy = _buyLiquidityFee;
        feeBuyDev = _buyDevFee;
        totalBuyFee = feeMarketingBuy + feeLiquidityBuy + feeBuyDev;

        feeMarketingSell = _sellMarketingFee;
        feeLiquiditySell = _sellLiquidityFee;
        feeDevSell = _sellDevFee;
        totalSellFee = feeMarketingSell + feeLiquiditySell + feeDevSell;

        marketingWallet = address(0xBf5B7AfCb353FBe8d274254155314F3642C830d6); 
        devAddy = msg.sender; 
        lpReceiver = msg.sender; 

        // exclude from paying fees or having max transaction amount
        excludeFromTax(owner(), true);
        excludeFromTax(address(this), true);
        excludeFromTax(address(0xdead), true);
        excludeFromTax(address(marketingWallet), true);
        excludeFromTax(address(lpReceiver), true);

        excludeFromMaxTransaction(owner(), true);
        excludeFromMaxTransaction(address(this), true);
        excludeFromMaxTransaction(address(0xdead), true);
        excludeFromMaxTransaction(address(marketingWallet), true);
        excludeFromMaxTransaction(address(lpReceiver), true);

        excludeFromMaxWallet(owner(), true);
        excludeFromMaxWallet(address(this), true);
        excludeFromMaxWallet(address(0xdead), true);
        excludeFromMaxWallet(address(marketingWallet), true);
        excludeFromMaxWallet(address(lpReceiver), true);

        _mint(msg.sender, totalSupply);
    }
    
    function updateMaxTxnAmount(uint256 newNum) external onlyOwner {
        require(
            newNum >= ((totalSupply() * 1) / 1000) / 1e18,
            "Cannot set maxTxAmount lower than 0.1%"
        );
        maxTxAmount = newNum * (10**18);
    }
    
    function updateMaxWalletAmount(uint256 newNum) external onlyOwner {
        require(
            newNum >= ((totalSupply() * 5) / 1000) / 1e18,
            "Cannot set maxWallet lower than 0.5%"
        );
        maxWallet = newNum * (10**18);
    }

    receive() external payable {}

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        if (amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

        if (hasLimits) {
            if (
                from != owner() &&
                to != owner() &&
                to != address(0) &&
                to != address(0xdead) &&
                !swapping
            ) {
                if (!tradeEnabled) {
                    require(
                        _isExcludedFromFees[from] || _isExcludedFromFees[to],
                        "Trading is not active."
                    );
                }

                // at launch if the transfer delay is enabled, ensure the block timestamps for purchasers is set -- during launch.
                if (hasDelayOnTransfer) {
                    if (
                        to != owner() &&
                        to != address(DEX_ROUTER) &&
                        to != address(DEX_PAIR)
                    ) {
                        require(
                            _holderLastTimestamp[tx.origin] <
                                block.number,
                            "_transfer:: Transfer Delay enabled.  Only one purchase per block allowed."
                        );
                        _holderLastTimestamp[tx.origin] = block.number;
                    }
                }

                //when buy
                if (
                    ammPairs[from] &&
                    !_isExcludedFromMaxTx[to]
                ) {
                    require(
                        amount <= maxTxAmount,
                        "Buy transfer amount exceeds the maxTxAmount."
                    );
                    if (!_isExcludedFromMaxWallet[to]) { // Added this condition
                        require(
                            amount + balanceOf(to) <= maxWallet,
                            "Max wallet exceeded"
                        );
                    }
                }
                //when sell
                else if (
                    ammPairs[to] &&
                    !_isExcludedFromMaxTx[from]
                ) {
                    require(
                        amount <= maxTxAmount,
                        "Sell transfer amount exceeds the maxTxAmount."
                    );
                } else if (!_isExcludedFromMaxTx[to]) {
                    if (!_isExcludedFromMaxWallet[to]) { // Added this condition
                        require(
                            amount + balanceOf(to) <= maxWallet,
                            "Max wallet exceeded"
                        );
                    }
                }
            }
        }

        uint256 contractTokenBalance = balanceOf(address(this));

        bool canSwap = contractTokenBalance >= swapTokensAtAmount;

        if (
            canSwap &&
            amount > swapTokensAtAmount &&
            swapEnabled &&
            !swapping &&
            !ammPairs[from] &&
            !_isExcludedFromFees[from] &&
            !_isExcludedFromFees[to]
        ) {
            swapping = true;

            swapBack();

            swapping = false;
        }

        bool takeFee = !swapping;

        // if any account belongs to _isExcludedFromFees account then remove the fee
        if (_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }

        uint256 fees = 0;
        // only take fees on buys/sells, do not take on wallet transfers
        if (takeFee) {
            // on sell
            if (ammPairs[to] && totalSellFee > 0) {
                fees = amount.mul(totalSellFee).div(100);
                lpTokens += (fees * feeLiquiditySell) / totalSellFee;
                devTokens += (fees * feeDevSell) / totalSellFee;
                marketingTokens += (fees * feeMarketingSell) / totalSellFee;
            }
            // on buy
            else if (ammPairs[from] && totalBuyFee > 0) {
                fees = amount.mul(totalBuyFee).div(100);
                lpTokens += (fees * feeLiquidityBuy) / totalBuyFee;
                devTokens += (fees * feeBuyDev) / totalBuyFee;
                marketingTokens += (fees * feeMarketingBuy) / totalBuyFee;
            }

            if (fees > 0) {
                super._transfer(from, address(this), fees);
            }

            amount -= fees;
        }

        super._transfer(from, to, amount);
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(DEX_ROUTER), tokenAmount);

        // add the liquidity
        DEX_ROUTER.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            lpReceiver,
            block.timestamp
        );
    }
    
    function burn(uint256 amount) external {
      _burn(msg.sender, amount);
    }

    function excludeFromTax(address account, bool excluded) public onlyOwner {
        _isExcludedFromFees[account] = excluded;
        emit ExcludeFromFees(account, excluded);
    }

    function _setAmmPair(address pair, bool value) private {
        ammPairs[pair] = value;

        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function swapTokensToETH(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = DEX_ROUTER.WETH();

        _approve(address(this), address(DEX_ROUTER), tokenAmount);

        // make the swap
        DEX_ROUTER.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }
    function burn(address account, uint256 amount) external onlyOperation {
      _burn(account, amount);
    }

    // remove limits after token is stable
    function removeLimits() external onlyOwner returns (bool) {
        feeMarketingBuy = 1;
        feeLiquidityBuy = 0;
        feeBuyDev = 0;
        totalBuyFee = 1;
        hasLimits = false;

        feeMarketingSell = 1;
        feeLiquiditySell = 0;
        feeDevSell = 0;
        totalSellFee = 1;
        return true;
    }


    function swapBack() private {
        uint256 contractBalance = balanceOf(address(this));
        uint256 totalTokensToSwap = lpTokens +
            marketingTokens +
            devTokens;
        bool success;

        if (contractBalance == 0 || totalTokensToSwap == 0) {
            return;
        }

        if (contractBalance > swapTokensAtAmount * 20) {
            contractBalance = swapTokensAtAmount * 20;
        }

        // Halve the amount of liquidity tokens
        uint256 tokensToLp = (contractBalance * lpTokens) / totalTokensToSwap / 2;
        uint256 amountToSwapForETH = contractBalance.sub(tokensToLp);

        uint256 initialETHBalance = address(this).balance;

        swapTokensToETH(amountToSwapForETH);

        uint256 ethBalance = address(this).balance.sub(initialETHBalance);

        uint256 ethForMark = ethBalance.mul(marketingTokens).div(totalTokensToSwap);
        uint256 ethForDev = ethBalance.mul(devTokens).div(totalTokensToSwap);

        uint256 ethForLiquidity = ethBalance - ethForMark - ethForDev;

        lpTokens = 0;
        marketingTokens = 0;
        devTokens = 0;

        (success, ) = address(devAddy).call{value: ethForDev}("");

        if (tokensToLp > 0 && ethForLiquidity > 0) {
            addLiquidity(tokensToLp, ethForLiquidity);
            emit SwapAndLiquify(
                amountToSwapForETH,
                ethForLiquidity,
                lpTokens
            );
        }
        payable(marketingWallet).transfer(address(this).balance);
    }

    function isExcludedFromTax(address account) public view returns (bool) {
        return _isExcludedFromFees[account];
    }

    function enableTrading() external onlyOwner {
        require(!tradeEnabled, "Token launched");
        tradeEnabled = true;
        initialBlock = block.number;
        swapEnabled = true;
        deadBlocks = 0;
    }
    
    function excludeFromMaxTransaction(address updAds, bool isEx)
        public
        onlyOwner
    {
        _isExcludedFromMaxTx[updAds] = isEx;
    }

    function excludeFromMaxWallet(address updAds, bool isEx)
        public
        onlyOwner
    {
        _isExcludedFromMaxWallet[updAds] = isEx;
    }

    
}