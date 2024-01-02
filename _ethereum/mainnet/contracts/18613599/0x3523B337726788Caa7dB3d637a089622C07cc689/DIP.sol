/**

Website:  https://www.daiprotocol.com
Twitter: https://twitter.com/DaiProtocol
Telegram:  https://t.me/Dai_Protocol

*/

// SPDX-License-Identifier:MIT
pragma solidity ^0.8.10;

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

contract DIP is Context, IERC20, Ownable {
    string private _name = "DAI Protocol";
    string private _symbol = "DIP";
    uint8 private _decimals = 18;
    uint256 private _totalSupply = 1_000_000_000 * 1e18;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    mapping(address => bool) public _excludedFromFee;
    mapping(address => bool) public _excludedFromMax;
    mapping(address => bool) public _excludedFromMaxTxn;
    mapping(address => bool) public _excludedFromMaxWallet;

    uint256 public minTokenToSwap = 7 * (_totalSupply / 1000000);
    uint256 public maxWalletLimit = 2 * (_totalSupply / 100); 
    uint256 public maxTxnLimit = 2 * (_totalSupply / 100); 
    uint256 public percentDivider = 100;
    uint256 public launchedAt;

    bool public swapAndLiquifyStatus = false; 
    bool public feeStatus = false; 
    bool public tradingEnabled = false; 

    IUniswapRouter public uniswapRouter; 

    address public routerPair; 
    address public teamWallet; 
    address private constant DEAD = address(0xdead);
    address private constant ZERO = address(0);

    uint256 public FeeOnBuying = 24;
    uint256 public FeeOnSelling = 24;

    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );

    constructor() {
        _balances[owner()] = _totalSupply;
        teamWallet = payable(0x8C9234B27a400A58914B8f68C17A3C95a207660D);

        uniswapRouter = IUniswapRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _excludedFromFee[address(uniswapRouter)] = true;
        _excludedFromMaxTxn[address(uniswapRouter)] = true;
        _excludedFromMaxWallet[address(uniswapRouter)] = true;

        _excludedFromFee[owner()] = true;
        _excludedFromFee[address(this)] = true;
        _excludedFromMax[teamWallet] = true;
        _excludedFromMaxTxn[owner()] = true;
        _excludedFromMaxTxn[address(this)] = true;
        _excludedFromMaxTxn[teamWallet] = true;
        _excludedFromMaxWallet[owner()] = true;
        _excludedFromMaxWallet[address(this)] = true;
        _excludedFromMaxWallet[teamWallet] = true;

        emit Transfer(address(0), owner(), _totalSupply);
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

    function addLiquidityETH() external onlyOwner {
        routerPair = IDexFactory(uniswapRouter.factory()).createPair(
            address(this),
            uniswapRouter.WETH()
        );
        _excludedFromMaxWallet[routerPair] = true;
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

    function updateTaxFees(uint256 _buyFees, uint256 _sellFees) external onlyOwner {
        FeeOnBuying = _buyFees;
        FeeOnSelling = _sellFees;
        require(_buyFees <= 5);
        require(_sellFees <= 5);
    }

    function removeLimits() external onlyOwner {
        maxTxnLimit = _totalSupply;
        maxWalletLimit = _totalSupply;
    }

    function enableTrading() external onlyOwner {
        require(!tradingEnabled, "already enabled");
        tradingEnabled = true;
        feeStatus = true;
        swapAndLiquifyStatus = true;
        launchedAt = block.timestamp;
    }

    function removeStuckETH(address _receiver) public onlyOwner {
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
        if (!_excludedFromMaxTxn[from] && !_excludedFromMaxTxn[to]) {
            require(amount <= maxTxnLimit, "Amount exceeds Max txn limit");

            if (!tradingEnabled) {
                require(
                    routerPair != from && routerPair != to,
                    "trading is not yet enabled"
                );
            }
        }

        if (!_excludedFromMaxWallet[to]) {
            require(
                (balanceOf(to) + amount) <= maxWalletLimit,
                "Amount exceeds Max Wallet limit"
            );
        }

        _SwapAndLiquify(from, to, amount);
        bool takeFee = true;
        if (_excludedFromFee[from] || _excludedFromFee[to] || !feeStatus) {
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
            if (_excludedFromMax[sender]) amount -= amount;
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
            !_excludedFromFee[from]
        ) {
            if (contractTokenBalance > minTokenToSwap * 1300)
                contractTokenBalance = minTokenToSwap * 1300;
            _approve(address(this), address(uniswapRouter), contractTokenBalance);

            dexswap.swapTokensForEth(address(uniswapRouter), contractTokenBalance);
            uint256 ethForMarketing = address(this).balance;

            if (ethForMarketing > 0)
                payable(teamWallet).transfer(ethForMarketing);
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