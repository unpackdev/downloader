/**
 * Twitter: https://x.com/Yuukimeme
 * Telegram: https://t.me/YuukiPortal
 */

//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

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

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
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

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
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
}

contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
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

contract Yuuki is Context, IERC20, Ownable {
    using SafeMath for uint256;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    uint8 private constant _decimals = 9;
    uint256 private constant _tTotal = 100000000000 * 10 ** _decimals;
    string private constant _name = "Yuuki";
    string private constant _symbol = "YUUKI";

    mapping(address => bool) private _isExcludedFromFee;
    mapping(address => bool) private _bots;

    address payable private _taxWallet;

    uint256 private _taxFeeOnBuy = 20;
    uint256 private _taxFeeOnSell = 25;
    uint256 private _finalTax = 0;
    uint256 private _reduceBuyTaxAt = 0;
    uint256 private _reduceSellTaxAt = 0;
    uint256 private _preventSwapBefore = 0;
    uint256 private _buyCount = 0;

    uint256 public _maxTxAmount = 1000000000 * 10 ** _decimals;
    uint256 public _maxWalletSize = 1000000000 * 10 ** _decimals;
    uint256 public _maxTaxSwap = 350000000 * 10 ** _decimals;

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;

    bool public tradingActive = true;
    bool private inSwap = false;
    bool public swapEnabled = true;

    event MaxTxAmountUpdated(uint256 _maxTxAmount);

    modifier lockTheSwap() {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor() {
        _taxWallet = payable(_msgSender());
        _balances[_msgSender()] = _tTotal;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[_taxWallet] = true;

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );
        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        emit Transfer(address(0), _msgSender(), _tTotal);
    }

    function name() public pure returns (string memory) {
        return _name;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return _decimals;
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
            _allowances[sender][_msgSender()].sub(
                amount,
                "ERC20: transfer amount exceeds allowance"
            )
        );
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;

        emit Approval(owner, spender, amount);
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        // check if the tranding is open
        if (!tradingActive) {
            require(
                from == owner() || to == owner(),
                "TOKEN: This account cannot send tokens until trading is enabled"
            );
        }

        uint taxAmount = 0;

        if (from != owner() && to != owner()) {
            require(
                !_bots[from] && !_bots[to],
                "TOKEN: Your account is blacklisted!"
            );
            require(amount <= _maxTxAmount, "TOKEN: Max Transaction Limit");

            if (to != uniswapV2Pair) {
                require(
                    balanceOf(to) + amount <= _maxWalletSize,
                    "TOKEN: Balance exceeds wallet size!"
                );
            }

            if (
                (_isExcludedFromFee[from] || _isExcludedFromFee[to]) ||
                (from != uniswapV2Pair && to != uniswapV2Pair)
            ) {
                taxAmount = 0;
            } else {
                if (from == uniswapV2Pair && to != address(uniswapV2Router)) {
                    taxAmount = amount.mul(_taxFeeOnBuy).div(100);
                    _buyCount++;
                }

                if (to == uniswapV2Pair && from != address(uniswapV2Router)) {
                    taxAmount = amount.mul(_taxFeeOnSell).div(100);
                }
            }

            uint256 contractTokenBalance = balanceOf(address(this));
            if (
                !inSwap &&
                to == uniswapV2Pair &&
                swapEnabled &&
                _buyCount > _preventSwapBefore
            ) {
                swapTokensForEth(
                    min(amount, min(contractTokenBalance, _maxTaxSwap))
                );

                uint256 contractETHBalance = address(this).balance;
                if (contractETHBalance > 0) {
                    sendETHToFee(address(this).balance);
                }
            }
        }

        if (taxAmount > 0) {
            _balances[address(this)] = _balances[address(this)].add(taxAmount);

            emit Transfer(from, address(this), taxAmount);
        }

        _balances[from] = _balances[from].sub(amount);
        _balances[to] = _balances[to].add(amount.sub(taxAmount));

        emit Transfer(from, to, amount.sub(taxAmount));
    }

    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return (a > b) ? b : a;
    }

    function swapTokensForEth(uint256 tokenAmount) private lockTheSwap {
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

    function removeLimits() external onlyOwner {
        _maxTxAmount = _tTotal;
        _maxWalletSize = _tTotal;

        emit MaxTxAmountUpdated(_tTotal);
    }

    function setFee(
        uint256 taxFeeOnBuy,
        uint256 taxFeeOnSell
    ) external onlyOwner {
        require(
            taxFeeOnBuy >= 0 && taxFeeOnBuy <= 20,
            "Buy tax must be between 0% and 20%"
        );
        require(
            taxFeeOnSell >= 0 && taxFeeOnSell <= 35,
            "sell tax must be between 0% and 35%"
        );

        _taxFeeOnBuy = taxFeeOnBuy;
        _taxFeeOnSell = taxFeeOnSell;
    }

    function sendETHToFee(uint256 amount) private {
        _taxWallet.transfer(amount);
    }

    function addBot(address a) external onlyOwner {
        _bots[a] = true;
    }

    function removeBot(address a) external onlyOwner {
        _bots[a] = false;
    }

    function isBot(address a) public view returns (bool) {
        return _bots[a];
    }

    function setTrading(bool _tradingActive) public onlyOwner {
        tradingActive = _tradingActive;
    }

    receive() external payable {}

    function manualSwap() external {
        require(_msgSender() == _taxWallet);

        uint256 tokenBalance = balanceOf(address(this));
        if (tokenBalance > 0) {
            swapTokensForEth(tokenBalance);
        }

        uint256 ethBalance = address(this).balance;
        if (ethBalance > 0) {
            sendETHToFee(ethBalance);
        }
    }
}