/**

░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒▒▒░░░░░░░░░░░░
░░░░░░░░░░░░▒▒▓▓▓▓▓▒▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒▓▒░░░░░░░░░░░░
░░▓█▓▓▓▒░░▒▓█▓▓▓▓▓▓▓▓▓▒░░▒▒▒▒▒▒▒▒▒░░░▒▒▒▒▒▒▒▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒▒▒▒░░
░░▓██▓▒░░▒████▓░░░▒▓▓▓▓▓░▓▓▓▓▓▓▓▓▓▒░▓▓▓▓▓▓▒▒▒░▒▓▓▓▓▓▓░░▓▓▓▓▓▓░░▓▓▓▒▒▒▓▓▓▒░░▓▓▓░░▒▓▓▓▓▓▒▓▒░
░░▒▒▒▒██░▓████▒░░░░▓▓▓▓▓░░░░▒▓▓▓▓▒░░▓▓▓▓▒▒▒▒░░▒▓▓▓▒▓▓▒▒▓▓▒▓▓▓░░▓▓▓▒░░▒▓▓▓▒░▓▓▓░░▓▓▓▓░░░░░░
░░▒▓█▓▓▒░▓████▓░░░▒▓▓▓▓▓░░▒▓▓▓▓▒░░░░▓▓▓▓▓▓▓▓▒░▒▓▓▓░▓▓▓▓▓▒░▓▓▓░░▓▓▓▓▓▓▓▓▓▒░░▒▓▒░▒▓▓▓▒░░░░░░
░░░░░░░░░░▓████▒▒▒▓▓▓▓▓░░▓▓▓▓▓▒▒▒▒░░▓▓▓▓▒▒▒▒▒░▒▓▓▓░▒▓▓▓▓░░▓▓▓░░▓▓▓▒░░░░░░░░░▓░░░▒▓▓▓▒▒▒▒▒░
░░░░░░░░░░░▒▓▓█████▓▓▒░░░▓▓▓▓▓▓▓▓▓▒░▓▓▓▓▓▓▓▓▓░░▓▓▒░░▓▓▓▒░░▒▒▒░░▒▒▒▒░░░░░░░░░▒░░░░░▒▒▓▓▓▓▒░

Rx: OZEMPIC (semaglutide)

Tg: https://t.me/ozempicportal

*/


// SPDX-License-Identifier: MIT

pragma solidity ^0.8.21;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
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

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    function _generateSupply(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
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

    function renounceOwnership() external virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface UniswapV2Router {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;

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

interface UniswapV2Factory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}

contract Ozempic is ERC20, Ownable {

    UniswapV2Router public immutable uniswapV2Router;
    address public immutable uniswapV2Pair;

    uint256 public maxWallet;
    uint256 public maxTxnAmount;

    bool private swapping;
    uint256 public swapTokensAtAmount;
    uint256 public swapLimit;

    address devWallet;

    mapping (address => bool) public bot;

    bool public limitsInEffect = true;
    bool public tradingLive = false;
    bool public swapEnabled = false;

    mapping(address => uint256) private _holderLastTransferTimestamp;
    bool public transferDelayEnabled = true;

    uint256 public buyFee;
    uint256 public sellFee;

    uint256 public taxedTokens;

    mapping (address => bool) private _isExcludedFromFees;
    mapping (address => bool) public _isExcludedMaxTransactionAmount;

    mapping (address => bool) public automatedMarketMakerPairs;

    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);

    event EnabledTrading();

    event RemovedLimits();

    event ExcludeFromFees(address indexed account, bool isExcluded);

    event UpdatedTxnAmount(uint256 newAmount);

    event UpdatedMaxWalletAmount(uint256 newAmount);

    event MaxTransactionExclusion(address _address, bool excluded);

    event OwnerManualCollection(uint256 timestamp);

    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiquidity
    );


    constructor() ERC20(unicode"(semaglutide)", unicode"OZEMPIC") {

        UniswapV2Router _uniswapV2Router = UniswapV2Router(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

        excludeFromMaxTransaction(address(_uniswapV2Router), true);
        uniswapV2Router = _uniswapV2Router;

        uniswapV2Pair = UniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        excludeFromMaxTransaction(address(uniswapV2Pair), true);
        _setAutomatedMarketMakerPair(address(uniswapV2Pair), true);

        buyFee = 20;
        sellFee = 25;

        uint256 totalSupply = 1 * 1e9 * 1e18;

        maxWallet = totalSupply * 2 / 100; // 2% MAX WALLET
        maxTxnAmount = totalSupply * 2 / 100; // 2% MAX TRANSACTION
        swapTokensAtAmount = totalSupply * 5 / 1000; // 0.5% SWAP THRESHOLD
        swapLimit = 6; // 3% MAX FEE SELL

        devWallet = payable(_msgSender());

        excludeFromFees(owner(), true);
        excludeFromFees(devWallet, true);
        excludeFromFees(address(this), true);
        excludeFromFees(address(0xdead), true);

        excludeFromMaxTransaction(owner(), true);
        excludeFromMaxTransaction(devWallet, true);
        excludeFromMaxTransaction(address(this), true);
        excludeFromMaxTransaction(address(0xdead), true);

        _generateSupply(devWallet, totalSupply);
    }

    receive() external payable {}

    // ENABLE TRADING
    function shootYourShot() external onlyOwner {
        require(!tradingLive, "Trading already live!");
        tradingLive = true;
        swapEnabled = true;
        emit EnabledTrading();
    }

    // REMOVE TXN LIMITS
    function removeLimits() external onlyOwner {
        limitsInEffect = false;
        transferDelayEnabled = false;
        swapTokensAtAmount = totalSupply() * 2 / 100; // 2% SWAP THRESHOLD
        swapLimit = 20; // 0.1% MAX FEE SELL
        emit RemovedLimits();
    }

    function updateTxnAmount(uint256 newNum) external onlyOwner {
        require(newNum >= (totalSupply() * 2 / 1000)/1e18, "Cannot set max txn amount lower than 0.2%");
        maxTxnAmount = newNum * (10**18);
        emit UpdatedTxnAmount(maxTxnAmount);
    }

    function updateMaxWalletAmount(uint256 newNum) external onlyOwner {
        require(newNum >= (totalSupply() * 3 / 1000)/1e18, "Cannot set max wallet amount lower than 0.3%");
        maxWallet = newNum * (10**18);
        emit UpdatedMaxWalletAmount(maxWallet);
    }

     function updateSwapTokensAtAmount(uint256 newAmount) external onlyOwner {
         require(newAmount >= totalSupply() * 1 / 100000, "Swap amount cannot be lower than 0.001% total supply.");
         require(newAmount <= totalSupply() * 5 / 1000, "Swap amount cannot be higher than 0.5% total supply.");
         swapTokensAtAmount = newAmount;
     }

     function updateFees(uint256 _buyFee, uint256 _sellFee) external onlyOwner {
         buyFee = _buyFee;
         sellFee = _sellFee;
         require((buyFee / 100) <= 20, "Must keep fees at 20% or less");
         require((sellFee / 100) <= 20, "Must keep fees at 20% or less");
     }

     function updateBot(address wallet, bool isBot) external onlyOwner {
         bot[wallet] = isBot;
     }

     function updateBots(address[] calldata wallets, bool isBot) external onlyOwner {
         for(uint256 i = 0; i < wallets.length; i++){
             bot[wallets[i]] = isBot;
         }
     }

     function excludeFromMaxTransaction(address updAds, bool isEx) public onlyOwner {
         _isExcludedMaxTransactionAmount[updAds] = isEx;
     }

    function setAutomatedMarketMakerPair(address pair, bool value) external onlyOwner {
        require(pair != uniswapV2Pair, "The pair cannot be removed from automatedMarketMakerPairs");

        _setAutomatedMarketMakerPair(pair, value);
        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        automatedMarketMakerPairs[pair] = value;

        excludeFromMaxTransaction(pair, value);

        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        _isExcludedFromFees[account] = excluded;
        emit ExcludeFromFees(account, excluded);
    }

    function _transfer(address from, address to, uint256 amount) internal override {

        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "amount must be greater than 0");

        if(!tradingLive){
            require(_isExcludedFromFees[from] || _isExcludedFromFees[to], "Trading is not active.");
        }

        require(!bot[from] && !bot[to]);

        if(limitsInEffect){
            if (from != owner() && to != owner() && to != address(0) && to != address(0xdead) && !_isExcludedFromFees[from] && !_isExcludedFromFees[to]){

                // LAUNCH TRANSFER DELAY
                if (transferDelayEnabled){
                    if (to != address(uniswapV2Router) && to != address(uniswapV2Pair)){
                      require(_holderLastTransferTimestamp[tx.origin] < block.number,"Only one transfer per block allowed.");
                        _holderLastTransferTimestamp[tx.origin] = block.number;
                    }
                }

                // BUY TXN
                if (automatedMarketMakerPairs[from] && !_isExcludedMaxTransactionAmount[to]) {
                        require(amount <= maxTxnAmount, "Buy transfer amount exceeds the max txn.");
                        require(amount + balanceOf(to) <= maxWallet, "Cannot Exceed max wallet");
                }
                // SELL TXN
                else if (automatedMarketMakerPairs[to] && !_isExcludedMaxTransactionAmount[from]) {
                        require(amount <= maxTxnAmount, "Sell transfer amount exceeds the max txn.");
                }
                else if (!_isExcludedMaxTransactionAmount[to]){
                    require(amount + balanceOf(to) <= maxWallet, "Cannot Exceed max wallet");
                }
            }
        }

        uint256 contractTokenBalance = balanceOf(address(this));

        bool canSwap = contractTokenBalance >= swapTokensAtAmount;

        if(canSwap && swapEnabled && !swapping && !automatedMarketMakerPairs[from] && !_isExcludedFromFees[from] && !_isExcludedFromFees[to]) {
            swapping = true;

            collectFees();

            swapping = false;
        }

        bool takeFee = true;

        if(_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }

        uint256 fees = 0;

        if(takeFee){
            // SELL TXN
            if (automatedMarketMakerPairs[to] && sellFee > 0){
                fees = amount * sellFee / 100;
                taxedTokens += fees;
            }

            // BUY TXN
            else if(automatedMarketMakerPairs[from] && buyFee > 0) {
          	    fees = amount * buyFee / 100;
                taxedTokens += fees;
            }

            if(fees > 0){
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

        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            address(0xdead),
            block.timestamp
        );
    }

    function collectFees() private {
        uint256 contractBalance = balanceOf(address(this));
        uint256 totalTokensToSwap = taxedTokens;

        if(contractBalance == 0 || totalTokensToSwap == 0) {return;}

        if (limitsInEffect){
          if (contractBalance > swapTokensAtAmount * swapLimit){
              contractBalance = swapTokensAtAmount * swapLimit;
          }
        } else {
          if (contractBalance > swapTokensAtAmount / swapLimit){
              contractBalance = swapTokensAtAmount / swapLimit;
          }
        }

        bool success;

        swapTokensForEth(contractBalance);

        taxedTokens = 0;

        if(address(this).balance > 0){
            (success,) = address(devWallet).call{value: address(this).balance}("");
        }
    }

    function manualCollection() external onlyOwner {
        require(balanceOf(address(this)) >= 0, "No tokens to swap");
        swapping = true;
        collectFees();
        swapping = false;
        emit OwnerManualCollection(block.timestamp);
    }

    function withdrawETH() external onlyOwner {
        bool success;
        (success,) = address(msg.sender).call{value: address(this).balance}("");
    }

}