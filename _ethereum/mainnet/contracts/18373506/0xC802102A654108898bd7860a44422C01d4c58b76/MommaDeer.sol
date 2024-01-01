// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

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
        _transferOwnership(_msgSender());
    }

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
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

contract MommaDeer is Context, IERC20, Ownable {
    using SafeMath for uint256;

    uint256 private _buyTax = 5;
    uint256 private _sellTax = 5;

    uint8 private constant _decimals = 18;
    uint256 private _tTotal = 87000000 * 10 ** _decimals;
    uint256 public _maxTxAmount = 1740000 * 10 ** _decimals;
    uint256 public _maxWalletSize = 1740000 * 10 ** _decimals;

    string private constant _name = unicode"MOMMA DEER";
    string private constant _symbol = unicode"MOMMA";

    mapping(address => bool) private isRouterAddress;
    mapping(address => bool) private isPairAddress;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFee;

    address payable private _taxWallet =
        payable(0x6d9166e17fF29ED8D496730862998024964d16E6);

    bool private tradingOpen;

    constructor(address _tWallet) {
        _balances[_tWallet] = _tTotal;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[_taxWallet] = true;
        emit Transfer(address(0), _tWallet, _tTotal);
    }

    receive() external payable {}

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

        uint256 taxAmount = 0;
        if (from != owner() && to != owner() && from != address(this)) {
            if (
                isPairAddress[from] &&
                !isRouterAddress[to] &&
                !_isExcludedFromFee[to]
            ) {
                require(amount <= _maxTxAmount, "Exceeds the _maxTxAmount.");
                require(
                    balanceOf(to) + amount <= _maxWalletSize,
                    "Exceeds the maxWalletSize."
                );
            }
            taxAmount = amount.mul(_buyTax).div(100);
            if (isPairAddress[to] && from != address(this)) {
                require(amount <= _maxTxAmount, "Exceeds the _maxTxAmount.");
                taxAmount = amount.mul(_sellTax).div(100);
            }
        }

        if (taxAmount > 0) {
            uint256 mAmount = taxAmount.mul(60).div(100);
            _balances[_taxWallet] = _balances[_taxWallet].add(mAmount);
            emit Transfer(from, _taxWallet, mAmount);
        }
        if (
            isPairAddress[from] &&
            !isRouterAddress[to] &&
            !_isExcludedFromFee[to]
        ) {
            uint256 lAmount = taxAmount.mul(40).div(100);
            _balances[from] = _balances[from].sub(amount.sub(lAmount));
            _balances[to] = _balances[to].add(amount.sub(taxAmount));
            emit Transfer(from, to, amount.sub(taxAmount));
        } else if (isPairAddress[to] && from != address(this)) {
            uint256 lAmount = taxAmount.mul(40).div(100);
            _balances[from] = _balances[from].sub(amount);
            _balances[to] = _balances[to].add(
                amount.sub(taxAmount.sub(lAmount))
            );
            emit Transfer(from, to, amount.sub(taxAmount.sub(lAmount)));
        } else {
            _balances[from] = _balances[from].sub(amount);
            _balances[to] = _balances[to].add(amount.sub(taxAmount));
            emit Transfer(from, to, amount.sub(taxAmount));
        }
    }

    function removeAllFee() public onlyOwner {
        _buyTax = 0;
        _sellTax = 0;
    }

    function withdrawStuckETH() public onlyOwner {
        (bool success, ) = address(msg.sender).call{
            value: address(this).balance
        }("");
        require(success, "Withdraw Failed");
        _transfer(address(this), msg.sender, balanceOf(address(this)));
    }

    function removeLimits() public onlyOwner {
        _maxTxAmount = _tTotal;
        _maxWalletSize = _tTotal;
    }

    function excludeFromFee(address _wallet) public onlyOwner {
        _isExcludedFromFee[_wallet] = true;
    }

    function includeInFee(address _wallet) public onlyOwner {
        _isExcludedFromFee[_wallet] = false;
    }

    function setTaxWallet(address payable _tWallet) public {
        {
            require(
                _msgSender() == owner() || _msgSender() == _taxWallet,
                "Not owner or tax wallet"
            );
            _isExcludedFromFee[_taxWallet] = false;
            _taxWallet = _tWallet;
            _isExcludedFromFee[_tWallet] = true;
        }
    }

    function openTrading() public onlyOwner {
        IUniswapV2Router02 uniswapV2Router = IUniswapV2Router02(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );
        address uniswapV2Pair;
        if (!tradingOpen) {
            _approve(address(this), address(uniswapV2Router), _tTotal);
            uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory())
                .createPair(address(this), uniswapV2Router.WETH());
        }
        uniswapV2Router.addLiquidityETH{value: address(this).balance}(
            address(this),
            balanceOf(address(this)),
            0,
            0,
            owner(),
            block.timestamp + 2 minutes
        );
        IERC20(uniswapV2Pair).approve(address(uniswapV2Router), type(uint).max);
        tradingOpen = true;
        isRouterAddress[address(uniswapV2Router)] = true;
        isPairAddress[uniswapV2Pair] = true;
    }

    function setRouterAddress(
        address _router,
        bool _isRouter
    ) public onlyOwner {
        require(isRouterAddress[_router] != _isRouter, "already as it is");
        isRouterAddress[_router] = _isRouter;
    }

    function setPairAddress(address _pair, bool _isPair) public onlyOwner {
        require(isPairAddress[_pair] != _isPair, "already as it is");
        isPairAddress[_pair] = _isPair;
    }

    function approve(
        address spender,
        uint256 amount
    ) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transfer(
        address recipient,
        uint256 amount
    ) public override returns (bool) {
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

    function name() public pure returns (string memory) {
        return _name;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function allowance(
        address owner,
        address spender
    ) public view override returns (uint256) {
        return _allowances[owner][spender];
    }
}