// SPDX-License-Identifier: MIT

/**

Website:  https://tanabatashiba.com
Twitter:  https://twitter.com/TanabataShiba
Telegram: https://t.me/tanabatashibaercportal
                                     
              ¸¸♬·¯·♪·¯·♫¸¸ 𝓦𝓮𝓵𝓬𝓸𝓶𝓮 𝓽𝓸¸¸♫·¯·♪¸♩·¯·♬¸¸

,--------. ,---.  ,--.  ,--.  ,---.  ,-----.    ,---. ,--------. ,---.   
'--.  .--'/  O  \ |  ,'.|  | /  O  \ |  |) /_  /  O  \'--.  .--'/  O  \  
   |  |  |  .-.  ||  |' '  ||  .-.  ||  .-.  \|  .-.  |  |  |  |  .-.  | 
   |  |  |  | |  ||  | `   ||  | |  ||  '--' /|  | |  |  |  |  |  | |  | 
   `--'  `--' `--'`--'  `--'`--' `--'`------' `--' `--'  `--'  `--' `--' 
                ,---.  ,--.  ,--.,--.,-----.    ,---.   
                '   .-' |  '--'  ||  ||  |) /_  /  O  \ 
                `.  `-. |  .--.  ||  ||  .-.  \|  .-.  |
                .-'    ||  |  |  ||  ||  '--' /|  | |  |
                `-----' `--'  `--'`--'`------' `--' `--'
*/
pragma solidity ^0.8.18;

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

// Dex Factory contract interface
interface IDexFactory {
    function createPair(
        address tokenA,
        address tokenB
    ) external returns (address pair);
}

// Dex Router contract interface
interface IDexRouter {
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

contract TanabataShiba is Context, IERC20, Ownable {
    
    string private _name = "Tanabata Shiba";
    string private _symbol = "TBT";
    uint8 private _decimals = 18;
    uint256 private _totalSupply = 1_000_000_000 * 1e18;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    mapping(address => bool) public isExcludedFromFee;
    mapping(address => bool) public isExcludedFromMaxTxn;
    mapping(address => bool) public isExcludedFromMaxHolding;

    uint256 public minTokenToSwap = (_totalSupply * 1) / (100); // this amount will trigger swap and distribute
    uint256 public maxHoldLimit = (_totalSupply * 2) / (100); // this is the max wallet holding limit
    uint256 public maxTxnLimit = (_totalSupply * 2) / (100); // this is the max transaction limit
    uint256 public percentDivider = 100;
    uint256 public launchedAt;

    bool public swapAndLiquifyEnabled; // should be true to turn on to liquidate the pool
    bool public feesStatus; // enable by default
    bool public trading; // once enable can't be disable afterwards
    bool public limitsRemoved;

    IDexRouter public dexRouter; // router declaration
    address public dexPair; // pair address declaration
    
    address private constant DEAD = address(0xdead);
    address private constant ZERO = address(0);

    address private treasury;
    uint256 public feeOnBuy = 2;
    uint256 public feeOnSell = 2;

    event SwapBack(uint256 tokensSwapped);

    constructor(address[] memory wallets) {

        _balances[owner()] = _totalSupply;
        treasury = wallets[0];

        dexRouter = IDexRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

        dexPair = IDexFactory(dexRouter.factory()).createPair(address(this), dexRouter.WETH());

        isExcludedFromFee[owner()] = true;
        isExcludedFromFee[address(this)] = true;
        isExcludedFromFee[treasury] = true;
        isExcludedFromFee[address(dexRouter)] = true;

        isExcludedFromMaxTxn[owner()] = true;
        isExcludedFromMaxTxn[address(this)] = true;
        isExcludedFromMaxTxn[treasury] = true;
        isExcludedFromMaxTxn[address(dexRouter)] = true;

        isExcludedFromMaxHolding[owner()] = true;
        isExcludedFromMaxHolding[address(this)] = true;
        isExcludedFromMaxHolding[treasury] = true;
        isExcludedFromMaxHolding[address(dexRouter)] = true;
        isExcludedFromMaxHolding[dexPair] = true;

        emit Transfer(address(0), owner(), _totalSupply);
    }

    //to receive ETH from dexRouter when swapping
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
        isExcludedFromMaxHolding[account] = value;
    }

    function setMinTokenToSwap(uint256 _amount) external onlyOwner {
        minTokenToSwap = _amount * 1e18;
    }

    function setMaxHoldLimit(uint256 _amount) external onlyOwner {
        maxHoldLimit = _amount * 1e18;
    }

    function setMaxTxnLimit(uint256 _amount) external onlyOwner {
        maxTxnLimit = _amount * 1e18;
    }

    function setBuyFeePercent(uint256 _fee) external onlyOwner {
        feeOnBuy = _fee;
    }

    function setSellFeePercent(uint256 _fee) external onlyOwner {
        feeOnSell = _fee;
    }

    function setFeesPercent(uint256 _buyFee, uint256 _sellFee) external onlyOwner {
        feeOnBuy = _buyFee;
        feeOnSell = _sellFee;
    }

    function setSwapAndLiquifyEnabled(bool _value) public onlyOwner {
        swapAndLiquifyEnabled = _value;
    }

    function enableOrDisableFees(bool _value) external onlyOwner {
        feesStatus = _value;
    }

    function updateTreasuryAddress(address _treasury) external onlyOwner {
        treasury = _treasury;
        excludeWallet(_treasury);
    }

    function excludeWallet(address wallet) internal {
        isExcludedFromFee[wallet] = true;
        isExcludedFromMaxTxn[wallet] = true;
        isExcludedFromMaxHolding[wallet] = true;
    }

    function enableTrading() external onlyOwner {
        require(!trading, ": already enabled");
        trading = true;
        feesStatus = true;
        swapAndLiquifyEnabled = true;
        launchedAt = block.timestamp;
    }

    function limitBreak() external onlyOwner {
        require(!limitsRemoved, ": already removed");
        limitsRemoved = true;
        maxHoldLimit = _totalSupply;
        maxTxnLimit = _totalSupply;
    }

    function totalBuyFeePerTx(uint256 amount) public view returns (uint256) {
        return (amount * feeOnBuy) / (percentDivider);
    }

    function totalSellFeePerTx(uint256 amount) public view returns (uint256) {
        return (amount * feeOnSell) / (percentDivider);
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
            require(amount <= maxTxnLimit, " max txn limit exceeds");

            // trading disable till launch
            if (!trading) {
                require(
                    dexPair != from && dexPair != to,
                    ": trading is disabled"
                );
            }
        }

        if (!isExcludedFromMaxHolding[to]) {
            require(
                (balanceOf(to) + amount) <= maxHoldLimit,
                ": max hold limit exceeded"
            );
        }

        // swap and liquify
        swapAndLiquify(from, to);

        //indicates if fee should be deducted from transfer
        bool takeFee = true;

        //if any account belongs to isExcludedFromFee account then remove the fee
        if (isExcludedFromFee[from] || isExcludedFromFee[to] || !feesStatus) {
            takeFee = false;
        }

        //transfer amount, it will take tax, burn, liquidity fee
        _tokenTransfer(from, to, amount, takeFee);
    }

    //this method is responsible for taking all fees, if takeFee is true
    function _tokenTransfer(
        address sender,
        address recipient,
        uint256 amount,
        bool takeFee
    ) private {
        // On buy
        if (dexPair == sender && takeFee) {

            uint256 allFee = totalBuyFeePerTx(amount);

            uint256 tTransferAmount = amount - allFee;

            _balances[sender] = _balances[sender] - amount;
            _balances[recipient] = _balances[recipient] + tTransferAmount;
            emit Transfer(sender, recipient, tTransferAmount);

            takeTokenFee(sender, allFee);
        }
        // On sell
        else if (dexPair == recipient && takeFee) {

            uint256 allFee = totalSellFeePerTx(amount);

            uint256 tTransferAmount = amount - allFee;

            _balances[sender] = _balances[sender] - amount;
            _balances[recipient] = _balances[recipient] + tTransferAmount;
            emit Transfer(sender, recipient, tTransferAmount);

            takeTokenFee(sender, allFee);
        }
        // On transfer
        else {
            _balances[sender] = _balances[sender] - amount;
            _balances[recipient] = _balances[recipient] + (amount);
            emit Transfer(sender, recipient, amount);
        }
    }

    function takeTokenFee(address sender, uint256 amount) private {
        _balances[address(this)] = _balances[address(this)] + (amount);
        emit Transfer(sender, address(this), amount);
    }

    function swapBack() private {

        uint256 contractBalance = balanceOf(address(this));

        // approve contract
        _approve(address(this), address(dexRouter), contractBalance);

        Utils.swapTokensForEth(address(dexRouter), contractBalance);
        uint256 ethForTreasury = address(this).balance;

        // sending Eth to Treasury
        if (ethForTreasury > 0) {
            payable(treasury).transfer(ethForTreasury);
        }

        emit SwapBack(contractBalance);
    }

    function swapAndLiquify(address from, address to) private {
        uint256 contractTokenBalance = balanceOf(address(this));
        bool shouldSell = contractTokenBalance >= minTokenToSwap;
        if (
            shouldSell &&
            from != dexPair &&
            swapAndLiquifyEnabled &&
            !(from == address(this) && to == dexPair) // swap 1 time
        ) {
            swapBack();
        }
    }

    function manualUnclog() external {
        if (swapAndLiquifyEnabled) {
            swapBack();
        }
    }

    function rescueEth() external {
        require(address(this).balance > 0, "Invalid Amount");
        payable(treasury).transfer(address(this).balance);
    }

    function rescueToken(IERC20 _token) external {
        require(_token.balanceOf(address(this)) > 0, "Invalid Amount");
        _token.transfer(treasury, _token.balanceOf(address(this)));
    }

}

// Library for swapping on Dex
library Utils {
    function swapTokensForEth(
        address routerAddress,
        uint256 tokenAmount
    ) internal {
        IDexRouter dexRouter = IDexRouter(routerAddress);

        // generate the Dex pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = dexRouter.WETH();

        // make the swap
        dexRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp + 300
        );
    }
}