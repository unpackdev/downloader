// SPDX-License-Identifier: MIT

/**
BetKing is a frictionless and verifiable TG betting bot. you can bet many famous sports on it without KYC.

Website: https://www.betking.games
Docs: https://docs.betking.games
Bot: https://t.me/betkingwinbot
Telegram:  https://t.me/BetKing_portal
Twitter: https://twitter.com/betking_eth

**/
pragma solidity 0.8.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

contract Ownable {
    address private _owner;
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
}

interface IUniswapV2Factory {
    function createPair(
        address tokenA,
        address tokenB
    ) external returns (address pair);
}

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
    )
        external
        payable
        returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);
}

contract BetToken is IERC20, Ownable {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFee;

    // tax distribut config
    uint256 private _taxDistributThreshold = 0.1 ether;
    address[] public taxWallets;
    mapping(address => uint) public taxPercentages;

    string private constant _name = unicode"BetKing";
    string private constant _symbol = unicode"BET";
    uint256 private constant _tTotal = 1000000 ether;

    uint256 public maxWalletSize = (_tTotal * 1) / 100;

    uint256 public buyTax = 5;
    uint256 public sellTax = 5;
    uint256 public taxToBlackHole = 1;

    address private blackHole = 0x000000000000000000000000000000000000dEaD;

    uint256 private _taxSwapThreshold = (_tTotal * 1) / 100;
    uint256 private _maxTaxSwap = (_tTotal * 1) / 100;

    uint256 private _highTaxBlock = 0;
    uint256 private _highTax = 5;

    IUniswapV2Router02 private uniswapV2Router =
        IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    address private uniswapV2Pair;
    bool private inSwap = false;
    bool private swapEnabled = false;
    uint256 private tradingStartBlock;

    bool public tradingOpen = false;

    event MaxWalletSizeUpdated(uint256 maxWalletSize);
    event TaxUpdated(uint256 buyTax, uint256 sellTax);

    modifier lockTheSwap() {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor() {
        _balances[msg.sender] = _tTotal;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;

        emit Transfer(address(0), msg.sender, _tTotal);
    }

    function name() public pure returns (string memory) {
        return _name;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return 18;
    }

    function totalSupply() public pure override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(
        address owner,
        address spender
    ) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(
        address spender,
        uint256 amount
    ) public override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender] - amount);
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        // only addresses that excluded from fee can transfer when trading is not open
        if (!tradingOpen) {
            require(
                _isExcludedFromFee[from],
                "This account cannot send tokens until trading is enabled"
            );
        }

        uint256 taxAmount = _getTaxAmount(from, to, amount);

        // swap tokens for eth
        uint256 contractTokenBalance = balanceOf(address(this));
        if (
            !inSwap &&
            to == uniswapV2Pair &&
            swapEnabled &&
            contractTokenBalance > _taxSwapThreshold
        ) {
            swapTokensForEth(
                min(amount, min(contractTokenBalance, _maxTaxSwap))
            );
            uint256 contractETHBalance = address(this).balance;
            if (
                contractETHBalance > 0 &&
                contractETHBalance > _taxDistributThreshold
            ) {
                distributTaxETH();
            }
        }

        if (taxAmount > 0) {
            // transfer tax to dead address
            uint256 deadTaxAmount = (amount * taxToBlackHole) / 100;
            _balances[blackHole] = _balances[blackHole] + deadTaxAmount;
            emit Transfer(address(this), blackHole, deadTaxAmount);

            // transfer tax to this contract
            _balances[address(this)] =
                _balances[address(this)] +
                taxAmount -
                deadTaxAmount;
            emit Transfer(from, address(this), taxAmount - deadTaxAmount);
        }

        _balances[from] = _balances[from] - amount;
        _balances[to] = _balances[to] + amount - taxAmount;
        emit Transfer(from, to, amount - taxAmount);
    }

    function _getTaxAmount(
        address from,
        address to,
        uint256 amount
    ) private view returns (uint256) {
        uint256 taxAmount = 0;

        // buy
        if (
            from == uniswapV2Pair &&
            to != address(uniswapV2Router) &&
            !_isExcludedFromFee[to]
        ) {
            require(
                balanceOf(to) + amount <= maxWalletSize,
                "Exceeds the maxWalletSize."
            );
            taxAmount = block.number >= tradingStartBlock + _highTaxBlock
                ? (amount * buyTax) / 100
                : (amount * _highTax) / 100;
        }

        // sale
        if (
            to == uniswapV2Pair &&
            from != address(this) &&
            !_isExcludedFromFee[from]
        ) {
            taxAmount = block.number >= tradingStartBlock + _highTaxBlock
                ? (amount * sellTax) / 100
                : (amount * _highTax) / 100;
        }

        return taxAmount;
    }

    // reduceTax
    function reduceTax(
        uint256 _buyTax,
        uint256 _sellTax,
        uint256 _taxToBlackHole
    ) external onlyOwner {
        require(_buyTax <= buyTax && _sellTax <= sellTax, "Invalid tax");
        require(
            _taxToBlackHole <= _buyTax && _taxToBlackHole <= _sellTax,
            "Invalid tax"
        );

        buyTax = _buyTax;
        sellTax = _sellTax;
        taxToBlackHole = _taxToBlackHole;

        emit TaxUpdated(buyTax, sellTax);
    }

    // add address to _isExcludedFromFee
    function addIsExcludedFromFee(address account) external onlyOwner {
        _isExcludedFromFee[account] = true;
    }

    function setTaxSwapConfig(
        uint256 taxSwapThreshold,
        uint256 maxTaxSwap
    ) external onlyOwner {
        _taxSwapThreshold = taxSwapThreshold;
        _maxTaxSwap = maxTaxSwap;
    }

    function removeLimits() external onlyOwner {
        maxWalletSize = _tTotal;
        emit MaxWalletSizeUpdated(_tTotal);
    }

    function openTrading(
        uint256 highTaxBlock,
        uint256 highTax,
        uint256 teamShare,
        uint256 _buyTax,
        uint256 _sellTax
    ) external onlyOwner {
        require(!tradingOpen, "trading is already open");
        require(taxWallets.length > 0, "taxWallets is empty");

        _approve(address(this), address(uniswapV2Router), _tTotal);

        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(
            address(this),
            uniswapV2Router.WETH()
        );

        uniswapV2Router.addLiquidityETH{value: address(this).balance}(
            address(this),
            balanceOf(address(this)) - teamShare,
            0,
            0,
            owner(),
            block.timestamp
        );

        _highTaxBlock = highTaxBlock;
        _highTax = highTax;

        buyTax = _buyTax;
        sellTax = _sellTax;

        swapEnabled = true;
        tradingOpen = true;
        tradingStartBlock = block.number;
    }

    function manualSwap() external {
        uint256 tokenBalance = balanceOf(address(this));
        if (tokenBalance > 0) {
            swapTokensForEth(tokenBalance);
        }
        uint256 ethBalance = address(this).balance;
        if (ethBalance > 0) {
            distributTaxETH();
        }
    }

    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return (a > b) ? b : a;
    }

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

    function distributTaxETH() public {
        for (uint i = 0; i < taxWallets.length; i++) {
            uint256 amount = (address(this).balance *
                taxPercentages[taxWallets[i]]) / 100;
            payable(taxWallets[i]).transfer(amount);
        }
    }

    function setTaxDistributConfig(
        uint256 taxDistributThreshold,
        address[] memory _taxWallets,
        uint[] memory _taxPercentages
    ) external onlyOwner {
        require(
            _taxWallets.length == _taxPercentages.length,
            "taxWallets and taxPercentages length mismatch"
        );

        _taxDistributThreshold = taxDistributThreshold;
        taxWallets = _taxWallets;

        uint count = 0;

        for (uint i = 0; i < _taxWallets.length; i++) {
            taxPercentages[_taxWallets[i]] = _taxPercentages[i];
            count += _taxPercentages[i];
        }

        require(count == 100, "Invalid taxPercentages");
    }

    receive() external payable {}
}