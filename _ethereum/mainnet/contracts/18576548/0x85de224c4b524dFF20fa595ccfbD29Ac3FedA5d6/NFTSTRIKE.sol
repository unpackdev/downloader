// SPDX-License-Identifier: MIT
pragma solidity ^0.8.5;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
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

    function transfer(address to, uint256 value) external returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);
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

    error OwnableUnauthorizedAccount(address account);

    error OwnableInvalidOwner(address owner);

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor(address initialOwner) {
        if (initialOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(initialOwner);
    }

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function _checkOwner() internal view virtual {
        if (owner() != _msgSender()) {
            revert OwnableUnauthorizedAccount(_msgSender());
        }
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        if (newOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IUniswapV2Router01 {
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

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

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

contract NFTSTRIKE is IERC20, Ownable {
    using SafeMath for uint256;

    string public constant name = "NFT STRIKE";
    string public constant symbol = "NFTS";
    uint8 public constant decimals = 18;

    uint256 private _totalSupply = 10000000000 * (10**uint256(decimals));
    uint256 private _maxTxAmount = (_totalSupply * 2) / 100;
    uint256 private _maxWalletSize = (_totalSupply * 2) / 100;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _liquidityFee = 2;
    uint256 private _buybackFee = 2;
    uint256 private _marketingFee = 1;
    uint256 private _devFee = 1;
    uint256 private _totalFee = 6;
    uint256 private _feeDenominator = 100;

    address private _marketingFeeReceiver =
        0x09F742130b672669fF16aa2fdA515F3473ca8aFa;
    address private _buybackFeeReceiver =
        0x2aAcc1ae2f82b6b45E067eC517dDEBDBab8E9e31;
    address private _devFeeReceiver =
        0x1Fc4a0124cD269A8E13533e100aCA377A7975Cb2;

    uint256 private _launchedAt;

    bool private _swapEnabled = true;
    uint256 private _swapThreshold = (_totalSupply / 1000) * 3; // 0.3%
    bool private _inSwap;
    bool private _isSwapBackEnabled;

    address private WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address private DEAD = 0x000000000000000000000000000000000000dEaD;
    address private ZERO = 0x0000000000000000000000000000000000000000;

    IUniswapV2Router02 private uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    IUniswapV2Factory private uniswapV2Factory = IUniswapV2Factory(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);
    address private uniswapV2Pair = uniswapV2Factory.createPair(address(this), WETH);

    constructor(address initialOwner)
        Ownable(initialOwner)
    {
        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    receive() external payable {}

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount)
        external
        override
        returns (bool)
    {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender)
        external
        view
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            msg.sender,
            _allowances[sender][msg.sender].sub(amount)
        );
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
        public
        returns (bool)
    {
        _approve(
            msg.sender,
            spender,
            _allowances[msg.sender][spender].add(addedValue)
        );
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        returns (bool)
    {
        _approve(
            msg.sender,
            spender,
            _allowances[msg.sender][spender].sub(subtractedValue)
        );
        return true;
    }

    function isOwner(address account) public view returns (bool) {
        return owner() == account;
    }

    function isAuthorized(address adr) public view returns (bool) {
        return owner() == adr;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "ERC20: transfer amount must be greater than zero");

        if (_inSwap) {
            _basicTransfer(sender, recipient, amount);
        } else {
            if (recipient != uniswapV2Pair && recipient != DEAD) {}
            if (shouldSwapBack(sender)) {
                _inSwap = true;
                swapBack();
                _inSwap = false;
            }
            if (!launched() && recipient == uniswapV2Pair) {
                require(_balances[sender] > 0);
                launch();
            }
            _balances[sender] = _balances[sender].sub(amount);
            uint256 amountReceived = takeFee(sender, recipient, amount);
            _balances[recipient] = _balances[recipient].add(amountReceived);
            emit Transfer(sender, recipient, amountReceived);
        }
    }

    function _basicTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal {
        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function takeFee(
        address sender,
        address receiver,
        uint256 amount
    ) internal returns (uint256) {
        uint256 feeAmount = amount
            .mul(getTotalFee(receiver == uniswapV2Pair))
            .div(_feeDenominator);
        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);
        return amount.sub(feeAmount);
    }

    function getTotalFee(bool selling) public view returns (uint256) {
        uint256 multiplier = AntiDumpMultiplier();
        if (selling) {
            return _totalFee.mul(multiplier);
        }
        return _totalFee;
    }

    function AntiDumpMultiplier() private view returns (uint256) {
        uint256 timeSinceStart = block.timestamp - _launchedAt;
        uint256 hour = 3600;
        if (timeSinceStart > 1 * hour) {
            return 1;
        } else {
            return 2;
        }
    }

    function shouldSwapBack(address from) internal view returns (bool) {
        return
            from != uniswapV2Pair &&
            !_inSwap &&
            _swapEnabled &&
            _balances[address(this)] >= _swapThreshold;
    }

    function swapBack() internal {
        uint256 contractTokenBalance = balanceOf(address(this));
        uint256 amountToLiquify = contractTokenBalance
            .mul(_liquidityFee)
            .div(_totalFee)
            .div(2);
        uint256 amountToSwap = contractTokenBalance.sub(amountToLiquify);

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = WETH;

        uint256 balanceBefore = address(this).balance;

        swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            path
        );

        uint256 amountBNB = address(this).balance.sub(balanceBefore);
        uint256 totalBNBFee = _totalFee.sub(_liquidityFee.div(2));
        uint256 amountBNBLiquidity = amountBNB
            .mul(_liquidityFee)
            .div(totalBNBFee)
            .div(2);
        uint256 amountBNBbuyback = amountBNB.mul(_buybackFee).div(totalBNBFee);
        uint256 amountBNBMarketing = amountBNB.mul(_marketingFee).div(
            totalBNBFee
        );
        uint256 amountBNBDev = amountBNB -
            amountBNBLiquidity -
            amountBNBbuyback -
            amountBNBMarketing;

        (bool MarketingSuccess, ) = payable(_marketingFeeReceiver).call{
            value: amountBNBMarketing,
            gas: 30000
        }("");
        require(MarketingSuccess, "receiver rejected ETH transfer");
        (bool BuyBackSuccess, ) = payable(_buybackFeeReceiver).call{
            value: amountBNBbuyback,
            gas: 30000
        }("");
        require(BuyBackSuccess, "receiver rejected ETH transfer");
        (bool DevSuccess, ) = payable(_devFeeReceiver).call{
            value: amountBNBDev,
            gas: 30000
        }("");
        require(DevSuccess, "receiver rejected ETH transfer");

        addLiquidity(amountToLiquify, amountBNBLiquidity);
    }

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] memory path
    ) internal {
        require(
            path[0] == address(this) && path[path.length - 1] == WETH,
            "Invalid path"
        );
        require(path.length > 1, "Invalid path");
        uint256[] memory amounts = uniswapV2Router.getAmountsOut(
            amountIn,
            path
        );
        require(
            amounts[amounts.length - 1] >= amountOutMin,
            "Slippage too high"
        );
        _approve(address(this), address(uniswapV2Router), amountIn);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountIn,
            amountOutMin,
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 BNBAmount) private {
        if (tokenAmount > 0) {
            _approve(address(this), address(uniswapV2Router), tokenAmount);
            uniswapV2Router.addLiquidityETH{value: BNBAmount}(
                address(this),
                tokenAmount,
                0,
                0,
                address(this),
                block.timestamp
            );
            emit AutoLiquify(BNBAmount, tokenAmount);
        }
    }

    function launched() internal view returns (bool) {
        return _launchedAt != 0;
    }

    function launch() internal {
        _launchedAt = block.timestamp;
    }

    function setFees(
        uint256 liquidityFee,
        uint256 buybackFee,
        uint256 devFee,
        uint256 marketingFee
    ) external onlyOwner {
        require(
            liquidityFee.add(buybackFee).add(marketingFee).add(devFee) < 25
        );
        require(_liquidityFee > 0);
        require(_totalFee > 0 );
        _liquidityFee = liquidityFee;
        _devFee = devFee;
        _buybackFee = buybackFee;
        _marketingFee = marketingFee;
        _totalFee = liquidityFee.add(buybackFee).add(marketingFee);
    }

    function setFeeReceiver(
        address marketingFeeReceiver,
        address buybackFeeReceiver
    ) external onlyOwner {
        _marketingFeeReceiver = marketingFeeReceiver;
        _buybackFeeReceiver = buybackFeeReceiver;
    }

    function setSwapBackSettings(bool enabled, uint256 amount)
        external
        onlyOwner
    {
        _swapEnabled = enabled;
        _swapThreshold = amount;
    }

    event AutoLiquify(uint256 amountBNB, uint256 amountToken);
}