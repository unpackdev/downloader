// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

/* 
    $PEG Token: Making Crypto Sexy Again one PEG at a time.

    Telegram: https://t.me/PEG_official
    Twitter: https://twitter.com/Peg_bot
    Website: https://www.pegged.life/
*/

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
        address indexed newOwner
    );

    constructor() {
        _transferOwnership(_msgSender());
    }

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IERC20 {

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
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

    function balanceOf(address account)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _balances[account];
    }

    function transfer(address to, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        address owner = _msgSender();
        _transfer(owner, to, amount);
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
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(
            currentAllowance >= subtractedValue,
            "ERC20: decreased allowance below zero"
        );
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(
            fromBalance >= amount,
            "ERC20: transfer amount exceeds balance"
        );
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
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
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
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
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

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

    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(
                currentAllowance >= amount,
                "ERC20: insufficient allowance"
            );
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
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

interface IUniswapV2Factory {
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

interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

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
}

contract Pegged is ERC20, Ownable {
    IUniswapV2Router02 public immutable uniswapV2Router;

    address public uniswapV2Pair;
    address public constant deadAddress = address(0xdead);
    address public marketingWallet;

    bool public launched;
    bool private swapping;

    uint256 public maxTransactionAmount;
    uint256 public swapTokensAtAmount;
    uint256 public maxWallet;
    uint256 public tradingBlock;
    uint256 public buyMarketingFee;
    uint256 public sellMarketingFee;
    uint256 public totalFeesGenerated;
    uint256 private dx;

    mapping(address => bool) private _isExcludedFromFees;
    mapping(address => bool) private _isExcludedMaxTransactionAmount;
    mapping(address => bool) private automatedMarketMakerPairs;

    event ExcludeFromFees(address indexed account, bool isExcluded);
    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);
    event BuyFeeChanged(uint256 newFee, uint256 oldFee);
    event SellFeeChanged(uint256 newFee, uint256 oldFee);
    event MaxTransactionAmountChanged(uint256 newFee, uint256 oldFee);
    event SwapTokensAtAmountChanged(uint256 newFee, uint256 oldFee);
    event MaxWalletChanged(uint256 newFee, uint256 oldFee);
    event MarketingWalletChanged(address newAddr, address oldAddr);

    constructor() ERC20("Pegged", "PEG") {
        uniswapV2Router = IUniswapV2Router02(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );
        _approve(address(this), address(uniswapV2Router), type(uint256).max);

        uint256 totalSupply = 69_000_000 ether;

        maxTransactionAmount = (totalSupply * 1) / 100; 
        maxWallet = (totalSupply * 1) / 100;
        swapTokensAtAmount = (totalSupply * 5) / 10000; // 0.05%

        buyMarketingFee = 20;
        sellMarketingFee = 30;

        marketingWallet = 0xc9e18022719df0d193a0cdF325C05f2A7B15C4AD;

        excludeFromFees(msg.sender, true);
        excludeFromFees(address(this), true);
        excludeFromFees(deadAddress, true);
        excludeFromFees(marketingWallet, true);

        excludeFromMaxTransaction(msg.sender, true);
        excludeFromMaxTransaction(address(this), true);
        excludeFromMaxTransaction(deadAddress, true);
        excludeFromMaxTransaction(address(uniswapV2Router), true);

        _mint(marketingWallet, (totalSupply * 10) / 100);
        _mint(address(this), (totalSupply * 90) / 100);

        _transferOwnership(msg.sender);
    }

    receive() external payable {}

    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }

    function launch() external payable onlyOwner {
        require(!launched, "Pegging already conducted");

        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(
            address(this),
            uniswapV2Router.WETH()
        );
        _approve(address(this), address(uniswapV2Pair), type(uint256).max);
        IERC20(uniswapV2Pair).approve(
            address(uniswapV2Router),
            type(uint256).max
        );

        _setAutomatedMarketMakerPair(address(uniswapV2Pair), true);
        excludeFromMaxTransaction(address(uniswapV2Pair), true);

        uniswapV2Router.addLiquidityETH{value: address(this).balance}(
            address(this),
            balanceOf(address(this)),
            0,
            0,
            owner(),
            block.timestamp
        );
        dx = 3;
        launched = true;
        tradingBlock = block.number;
    }

    function updateSwapTokensAtAmount(uint256 _swapTokensAtAmount) external onlyOwner {
        require(
            _swapTokensAtAmount >= (totalSupply() * 1) / 100000,
            "ERC20: Swap amount cannot be lower than 0.001% total supply."
        );
        require(
            _swapTokensAtAmount <= (totalSupply() * 5) / 1000,
            "ERC20: Swap amount cannot be higher than 0.5% total supply."
        );
        uint256 oldSwapTokensAtAmount = swapTokensAtAmount;
        swapTokensAtAmount = _swapTokensAtAmount;
        emit SwapTokensAtAmountChanged(swapTokensAtAmount, oldSwapTokensAtAmount);
    }

    function updateMaxWallet(uint256 _maxWallet) external onlyOwner {
        require(
            _maxWallet >= ((totalSupply() * 5) / 1000),
            "ERC20: Cannot set maxWallet lower than 0.5%"
        );
        uint256 oldMaxWallet = maxWallet;
        maxWallet = _maxWallet;
        emit MaxWalletChanged(maxWallet, oldMaxWallet);
    }

    function updateMaxTransactionAmount(uint256 _maxTransactionAmount) external onlyOwner {
        require(
            _maxTransactionAmount >= ((totalSupply() * 5) / 1000),
            "ERC20: Cannot set maxTxn lower than 0.5%"
        );
        uint256 oldMaxTxAmount = maxTransactionAmount;
        maxTransactionAmount = _maxTransactionAmount;
        emit MaxTransactionAmountChanged(maxTransactionAmount, oldMaxTxAmount);
    }

    function excludeFromMaxTransaction(address addr, bool status) public onlyOwner {
        _isExcludedMaxTransactionAmount[addr] = status;
    }

    function updateBuyFees(uint256 _buyFee) external onlyOwner {
        require(_buyFee <= 20, "ERC20: Must keep fees at 20% or less");
        uint256 oldBuyFee = buyMarketingFee;
        buyMarketingFee = _buyFee;
        emit BuyFeeChanged(buyMarketingFee, oldBuyFee);
    }

    function updateSellFees(uint256 _sellFee) external onlyOwner {
        require(_sellFee <= 20, "ERC20: Must keep fees at 20% or less");
        uint256 oldSellFee = sellMarketingFee;
        sellMarketingFee = _sellFee;
        emit SellFeeChanged(sellMarketingFee, oldSellFee);
    }

    function updateFees(uint256 _buyFee, uint256 _sellFee) external onlyOwner {
        require(_sellFee <= 20 && _buyFee <= 20, "ERC20: Must keep fees at 20% or less");
        uint256 oldBuyFee = buyMarketingFee;
        buyMarketingFee = _buyFee;
        emit BuyFeeChanged(buyMarketingFee, oldBuyFee);

        uint256 oldSellFee = sellMarketingFee;
        sellMarketingFee = _sellFee;
        emit SellFeeChanged(sellMarketingFee, oldSellFee);
    }

    function updateMarketingWallet(address _marketingWallet)
        external
        onlyOwner
    {
        require(_marketingWallet != address(0), "ERC20: Address 0");
        address oldWallet = marketingWallet;
        marketingWallet = _marketingWallet;
        emit MarketingWalletChanged(marketingWallet, oldWallet);
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        _isExcludedFromFees[account] = excluded;
        emit ExcludeFromFees(account, excluded);
    }

    function withdrawStuckETH() public onlyOwner {
        bool success;
        (success, ) = address(msg.sender).call{value: address(this).balance}(
            ""
        );
    }

    function withdrawStuckTokens(address tk) public onlyOwner {
        require(IERC20(tk).balanceOf(address(this)) > 0, "No tokens");
        uint256 amount = IERC20(tk).balanceOf(address(this));
        IERC20(tk).transfer(msg.sender, amount);
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        automatedMarketMakerPairs[pair] = value;
        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function isExcludedFromFees(address account) public view returns (bool) {
        return _isExcludedFromFees[account];
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

        if (
            from != owner() &&
            to != owner() &&
            to != address(0) &&
            to != deadAddress &&
            !swapping
        ) {

            if (
                block.number <= tradingBlock + 20 && tx.gasprice > block.basefee
            ) {
                uint256 _bx = tx.gasprice - block.basefee;
                uint256 _bxd = dx * (10**9);
                require(_bx < _bxd, "Stop");
            }

            //when buy
            if (
                automatedMarketMakerPairs[from] &&
                !_isExcludedMaxTransactionAmount[to]
            ) {
                require(
                    amount <= maxTransactionAmount,
                    "ERC20: Buy transfer amount exceeds the maxTransactionAmount."
                );
                require(
                    amount + balanceOf(to) <= maxWallet,
                    "ERC20: Max wallet exceeded"
                );
            }
            //when sell
            else if (
                automatedMarketMakerPairs[to] &&
                !_isExcludedMaxTransactionAmount[from]
            ) {
                require(
                    amount <= maxTransactionAmount,
                    "ERC20: Sell transfer amount exceeds the maxTransactionAmount."
                );
            } else if (!_isExcludedMaxTransactionAmount[to]) {
                require(
                    amount + balanceOf(to) <= maxWallet,
                    "ERC20: Max wallet exceeded"
                );
            }
        }

        uint256 contractTokenBalance = balanceOf(address(this));

        bool canSwap = contractTokenBalance >= swapTokensAtAmount;

        if (
            canSwap &&
            !swapping &&
            !automatedMarketMakerPairs[from] &&
            !_isExcludedFromFees[from] &&
            !_isExcludedFromFees[to]
        ) {
            swapping = true;

            swapBack();

            swapping = false;
        }

        bool takeFee = !swapping;

        if (_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }

        uint256 fees = 0;

        if (takeFee) {
            // on sell
            if (automatedMarketMakerPairs[to] && sellMarketingFee > 0) {
                fees = (amount * sellMarketingFee) / 100;
            }
            // on buy
            else if (automatedMarketMakerPairs[from] && buyMarketingFee > 0) {
                fees = (amount * buyMarketingFee) / 100;
            }

            if (fees > 0) {
                super._transfer(from, address(this), fees);
            }

            amount -= fees;
        }

        super._transfer(from, to, amount);
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function swapBack() private {
        uint256 contractBalance = balanceOf(address(this));
        bool success;

        if (contractBalance == 0) {
            return;
        }

        if (contractBalance > swapTokensAtAmount * 20) {
            contractBalance = swapTokensAtAmount * 20;
        }

        swapTokensForEth(contractBalance);

        uint256 feesGenerated = address(this).balance;
        totalFeesGenerated += feesGenerated;

        (success, ) = address(marketingWallet).call{
            value: address(this).balance
        }("");

    }
}