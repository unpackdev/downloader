/*
.___________. __    __   _______      ______   .__   __.  __      ____    ____    ____    __    ____      ___      ____    ____     __       _______.    __    __  .______    __
|           ||  |  |  | |   ____|    /  __  \  |  \ |  | |  |     \   \  /   /    \   \  /  \  /   /     /   \     \   \  /   /    |  |     /       |   |  |  |  | |   _  \  |  |
`---|  |----`|  |__|  | |  |__      |  |  |  | |   \|  | |  |      \   \/   /      \   \/    \/   /     /  ^  \     \   \/   /     |  |    |   (----`   |  |  |  | |  |_)  | |  |
    |  |     |   __   | |   __|     |  |  |  | |  . `  | |  |       \_    _/        \            /     /  /_\  \     \_    _/      |  |     \   \       |  |  |  | |   ___/  |  |
    |  |     |  |  |  | |  |____    |  `--'  | |  |\   | |  `----.    |  |           \    /\    /     /  _____  \      |  |        |  | .----)   |      |  `--'  | |  |      |__|
    |__|     |__|  |__| |_______|    \______/  |__| \__| |_______|    |__|            \__/  \__/     /__/     \__\     |__|        |__| |_______/        \______/  | _|      (__)

Welcome to UP Staking Dapp! Here we share 50% of the trading revenue to our stakers! 
Stake your $UP and claim your rewards in real ETH any where any time!

Dapp: https://www.upstaking.today
TG: https://t.me/upStakingDappPortal
X: https://www.x.com/UpStakingDapp

*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import "./IERC20.sol";
import "./Ownable.sol";
import "./Address.sol";

interface IStaking {
    function stake(address, uint) external;
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

contract UP is Context, IERC20, Ownable {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFee;
    IStaking public staking;
    uint256 private firstBlock;
    uint256 public startTime;

    uint256 private _initialBuyTax = 20;
    uint256 private _initialSellTax = 20;
    uint256 private _finalBuyTax = 5;
    uint256 private _finalSellTax = 5;
    uint256 private _reduceBuyTaxAt = 15;
    uint256 private _reduceSellTaxAt = 15;
    uint256 private _preventSwapBefore = 0;
    uint256 private _buyCount = 0;
    uint8 private constant _decimals = 18;
    uint256 private constant _tTotal = 1000000 * 10 ** _decimals;
    string private constant _name = unicode"UP Staking Dapp Token";
    string private constant _symbol = unicode"UP";
    uint256 public _maxTxAmount = 20000 * 10 ** _decimals;
    uint256 public _maxWalletSize = 20000 * 10 ** _decimals;
    uint256 public _taxSwapThreshold = 10000 * 10 ** _decimals;
    uint256 public _maxTaxSwap = 10000 * 10 ** _decimals;

    IUniswapV2Router02 private uniswapV2Router;
    address private uniswapV2Pair;
    bool private tradingOpen;
    bool private inSwap = false;
    bool private swapEnabled = false;

    event MaxTxAmountUpdated(uint _maxTxAmount);

    modifier lockTheSwap() {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor(IStaking staking_) Ownable(_msgSender()) {
        staking = staking_;
        _balances[_msgSender()] = _tTotal;
        _isExcludedFromFee[_msgSender()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[address(staking_)] = true;

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
            _allowances[sender][_msgSender()] - amount
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
        uint256 taxAmount = 0;

        if (from != owner() && to != owner()) {
            if (
                from == uniswapV2Pair &&
                to != address(uniswapV2Router) &&
                !_isExcludedFromFee[to]
            ) {
                taxAmount =
                    (amount *
                        (
                            _buyCount > _reduceBuyTaxAt
                                ? _finalBuyTax
                                : _initialBuyTax
                        )) /
                    100;
                require(amount <= _maxTxAmount, "Exceeds the _maxTxAmount.");
                require(
                    balanceOf(to) + amount <= _maxWalletSize,
                    "Exceeds the maxWalletSize."
                );

                _buyCount++;
            }

            if (to != uniswapV2Pair && !_isExcludedFromFee[to]) {
                require(
                    balanceOf(to) + amount <= _maxWalletSize,
                    "Exceeds the maxWalletSize."
                );
            }

            if (to == uniswapV2Pair && from != address(this)) {
                taxAmount =
                    (amount *
                        (
                            (_buyCount > _reduceSellTaxAt)
                                ? _finalSellTax
                                : _initialSellTax
                        )) /
                    100;
            }

            uint256 contractTokenBalance = balanceOf(address(this));
            if (
                !inSwap &&
                to == uniswapV2Pair &&
                swapEnabled &&
                contractTokenBalance > _taxSwapThreshold &&
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
            _balances[address(this)] = _balances[address(this)] + taxAmount;
            emit Transfer(from, address(this), taxAmount);
        }

        _balances[from] = _balances[from] - amount;
        _balances[to] = _balances[to] + (amount - taxAmount);
        emit Transfer(from, to, amount - taxAmount);

        if (to == address(staking)) {
            staking.stake(from, amount - taxAmount);
        }
    }

    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return a > b ? b : a;
    }

    function isContract(address account) private view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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

    function sendETHToFee(uint256 amount) private {
        Address.sendValue(payable(address(staking)), amount);
    }

    function openTrading() external onlyOwner {
        require(!tradingOpen, "trading is already open");
        uniswapV2Router = IUniswapV2Router02(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );
        _approve(address(this), address(uniswapV2Router), _tTotal);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(
                address(this),
                uniswapV2Router.WETH()
            );
        uniswapV2Router.addLiquidityETH{value: address(this).balance}(
            address(this),
            balanceOf(address(this)),
            0,
            0,
            owner(),
            block.timestamp
        );
        IERC20(uniswapV2Pair).approve(address(uniswapV2Router), type(uint).max);

        swapEnabled = true;
        tradingOpen = true;
        firstBlock = block.number;
        startTime = block.timestamp;
    }

    receive() external payable {}
}
