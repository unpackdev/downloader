// SPDX-License-Identifier: MIT

/**
Website:  https://balanceof.capital
Docs:     https://docs.balanceof.capital

Twitter:   https://twitter.com/boc_protocol
Telegram:  https://t.me/balanceofcapital
**/

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

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
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

    function getAmountsOut(
        uint amountIn,
        address[] memory path
    ) external view returns (uint[] memory amounts);

    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    )
        external
        payable
        returns (uint amountToken, uint amountETH, uint liquidity);
}

contract BOCTOKEN is Context, IERC20, Ownable {
    using SafeMath for uint256;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFee;
    mapping(address => bool) public isMarketMakerPair;

    address payable private _devWallet = payable(0xC1365B0adA58116072E762350544e324332D09b8);

    uint8 private constant _decimals = 9;
    uint256 private constant _tTotal = 100_000_000 * 10 ** _decimals;
    string private constant _name = unicode"Balance of Captial";
    string private constant _symbol = unicode"BOC";

    uint256 private _buyInitialTax = 20;
    uint256 private _totalBuyTax = 20;
    uint256 private _sellInitialTax = 20;
    uint256 private _totalSellTax = 20;

    uint256 public _maxTxAmount = (_tTotal * 20) / 1000;

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;

    bool private tradingActive = false;
    bool private inSwap = false;
    bool private swapEnabled = false;

    event _maxTxAmountUpdated(uint _maxTxAmount);
    modifier lockTheSwap() {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor() {
        setIsExcludedFromFees(owner(), true);
        setIsExcludedFromFees(_devWallet, true);
        setIsExcludedFromFees(address(this), true);

        _mint(_msgSender(), (_tTotal * 5) / 100);
        _mint(address(this), (_tTotal * 95) / 100);
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

        if(!_isExcludedFromFee[from] && !_isExcludedFromFee[to]){
            require(tradingActive, "Trading had not opened yet.");
        }

        if (
            isMarketMakerPair[from] &&
            to != address(uniswapV2Router) &&
            !_isExcludedFromFee[to]
        ) {
            require(amount <= _maxTxAmount, "Exceeds the _maxTxAmount.");
        }
        
        if (inSwap || (from == address(this) || to == address(this))) {
            _balances[from] = _balances[from].sub(amount);
            _balances[to] = _balances[to].add(amount);
            emit Transfer(from, to, amount);
        } else {
            uint256 contractTokenBalance = balanceOf(address(this));

            if (
                !inSwap &&
                !isMarketMakerPair[from] &&
                swapEnabled &&
                !_isExcludedFromFee[from] &&
                !_isExcludedFromFee[to] &&
                contractTokenBalance > 0
            ) {
                swapTokensForEth(contractTokenBalance);
                uint256 contractETHBalance = address(this).balance;
                if (contractETHBalance > 0) {
                    sendETHToFee(address(this).balance);
                }
            }

            uint256 taxAmount = 0;
            bool takeFee = true;

            if (_isExcludedFromFee[from] && !isMarketMakerPair[to]) {
                taxAmount = amount.mul(_totalBuyTax).div(100);
                if (taxAmount >= 0)
                    _balances[_devWallet] = _balances[_devWallet].add(taxAmount);
                emit Transfer(from, _devWallet, taxAmount);
                takeFee = false;
            }

            if (takeFee) {
                taxAmount = amount.mul(_buyInitialTax).div(100);

                if (isMarketMakerPair[to] && from != address(this)) {
                    taxAmount = amount.mul(_sellInitialTax).div(100);
                }

                if (taxAmount > 0) {
                    _balances[address(this)] = _balances[address(this)].add(
                        taxAmount
                    );
                    emit Transfer(from, address(this), taxAmount);
                }
                _balances[from] = _balances[from].sub(amount);
                _balances[to] = _balances[to].add(amount.sub(taxAmount));
                emit Transfer(from, to, amount.sub(taxAmount));
            }
        }
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

    function sendETHToFee(uint256 amount) internal {
        _devWallet.transfer(amount);
    }

    function removeLimit() external onlyOwner {
        _maxTxAmount = ~uint256(0);

        _buyInitialTax = 2;
        _sellInitialTax = 2;

        emit _maxTxAmountUpdated(~uint256(0));
    }

    function setIsExcludedFromFees(
        address account,
        bool newValue
    ) public onlyOwner {
        _isExcludedFromFee[account] = newValue;
    }

    function _mint(address account, uint256 amount) private {
        _balances[account] = amount;
        emit Transfer(address(0), account, amount);
    }

    function _setMarketPairStatus(address account, bool newValue) private {
        isMarketMakerPair[account] = newValue;
    }

    function setMarketPairStatus(
        address account,
        bool newValue
    ) public onlyOwner {
        require(
            account != uniswapV2Pair,
            "The pair cannot be removed from isAMMPair"
        );
        isMarketMakerPair[account] = newValue;
    }

    function addLiquidityETH() external payable onlyOwner {
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );

        uniswapV2Router = _uniswapV2Router;

        _approve(address(this), address(uniswapV2Router), ~uint256(0));

        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(
            address(this),
            uniswapV2Router.WETH()
        );
        _setMarketPairStatus(uniswapV2Pair, true);

        uniswapV2Router.addLiquidityETH{value: msg.value}(
            address(this),
            balanceOf(address(this)),
            0,
            0,
            owner(),
            block.timestamp
        );
    }

    function enableTrading() external onlyOwner {
        require(!tradingActive, "trading is already open");
        swapEnabled = true;
        tradingActive = true;
    }

    receive() external payable {}

    function manualSwap() external onlyOwner {
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