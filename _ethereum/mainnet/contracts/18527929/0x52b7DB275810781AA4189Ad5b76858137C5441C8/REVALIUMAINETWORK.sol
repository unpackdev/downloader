/**
 *Submitted for verification at Etherscan.io on 2023-08-21
*/

// SPDX-License-Identifier: MIT

/*
// REVALIUM AI NETWORK

┏━━━┓ ┏━━━┓ ┏┓︱︱┏┓ ┏━━━┓ ┏┓︱︱︱ ┏━━┓ ┏┓︱┏┓ ┏━┓┏━┓   ┏━━━┓ ┏━━┓   ┏━┓︱┏┓ ┏━━━┓ ┏━━━━┓ ︱︱︱︱︱︱ ┏━━━┓ ┏━━━┓ ┏┓┏━┓
┃┏━┓┃ ┃┏━━┛ ┃┗┓┏┛┃ ┃┏━┓┃ ┃┃︱︱︱ ┗┫┣┛ ┃┃︱┃┃ ┃┃┗┛┃┃   ┃┏━┓┃ ┗┫┣┛   ┃┃┗┓┃┃ ┃┏━━┛ ┃┏┓┏┓┃ ︱︱︱︱︱︱ ┃┏━┓┃ ┃┏━┓┃ ┃┃┃┏┛
┃┗━┛┃ ┃┗━━┓ ┗┓┃┃┏┛ ┃┃︱┃┃ ┃┃︱︱︱ ︱┃┃︱ ┃┃︱┃┃ ┃┏┓┏┓┃   ┃┃︱┃┃ ︱┃┃︱   ┃┏┓┗┛┃ ┃┗━━┓ ┗┛┃┃┗┛ ┏┓┏┓┏┓ ┃┃︱┃┃ ┃┗━┛┃ ┃┗┛┛︱
┃┏┓┏┛ ┃┏━━┛ ︱┃┗┛┃︱ ┃┗━┛┃ ┃┃︱┏┓ ︱┃┃︱ ┃┃︱┃┃ ┃┃┃┃┃┃   ┃┗━┛┃ ︱┃┃︱   ┃┃┗┓┃┃ ┃┏━━┛ ︱︱┃┃︱︱ ┃┗┛┗┛┃ ┃┃︱┃┃ ┃┏┓┏┛ ┃┏┓┃︱
┃┃┃┗┓ ┃┗━━┓ ︱┗┓┏┛︱ ┃┏━┓┃ ┃┗━┛┃ ┏┫┣┓ ┃┗━┛┃ ┃┃┃┃┃┃   ┃┏━┓┃ ┏┫┣┓   ┃┃︱┃┃┃ ┃┗━━┓ ︱︱┃┃︱︱ ┗┓┏┓┏┛ ┃┗━┛┃ ┃┃┃┗┓ ┃┃┃┗┓
┗┛┗━┛ ┗━━━┛ ︱︱┗┛︱︱ ┗┛︱┗┛ ┗━━━┛ ┗━━┛ ┗━━━┛ ┗┛┗┛┗┛   ┗┛︱┗┛ ┗━━┛   ┗┛︱┗━┛ ┗━━━┛ ︱︱┗┛︱︱ ︱┗┛┗┛︱ ┗━━━┛ ┗┛┗━┛ ┗┛┗━┛

REVALIUM AI NETWORK

Revalium for everyone!

Revalium AI Network Architecture:  Blockchain Infrastructure: Revalium AI Network utilizes a robust and scalable blockchain infrastructure that ensures transparency, security and immutability. The platform is built on a distributed ledger that enables seamless integration with external AI service providers while maintaining data privacy and security.

Artificial Intelligence Integration: Revalium AI Network integrates with various AI service providers, leveraging their expertise and cutting-edge AI models. The platform connects users to these providers through a secure API, providing real-time AI analysis and responses. Revalium AI Network continuously evaluates and collaborates with AI providers to expand the range of services available to users.

In the next stage, various improvements come.
⬇️🔜

🤖Get ready for a big change in the crypto world! Revalium multifunction bots and blockchain network service is coming for you!

🤖 A completely free project that will lead everyone to win with various trade bots!

Revalium AI Network Bot can also be used for market forecasts and sentiment analysis. Users can leverage the Telegram bot to analyze market data, predict trends and get real-time insights, enabling them to make informed investment decisions and optimize their trading strategies.

  Telegram: https://t.me/RevaliumNetwork
     X: https://twitter.com/revaliumnetwork
  Website: https://www.revaliumainetwork.com (UPDATE COMING SOON)

*/

pragma solidity 0.8.20;

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

contract REVALIUMAINETWORK is Context, IERC20, Ownable {
    using SafeMath for uint256;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFee;
    mapping(address => bool) private bots;
    mapping(address => uint256) private _holderLastTransferTimestamp;
    bool public transferDelayEnabled = true;
    address payable private _taxWallet;

    uint256 private _initialBuyTax = 29;
    uint256 private _initialSellTax = 34;
    uint256 private _finalBuyTax = 4;
    uint256 private _finalSellTax = 4;
    uint256 private _reduceBuyTaxAt = 29;
    uint256 private _reduceSellTaxAt = 34;
    uint256 private _preventSwapBefore = 65;
    uint256 private _buyCount = 0;

    uint8 private constant _decimals = 9;
    uint256 private constant _tTotal = 100000000 * 10 ** _decimals;
    string private constant _name = unicode"REVALIUMAINETWORK";
    string private constant _symbol = unicode"RVAI";
    uint256 public _maxTxAmount = 2000000 * 10 ** _decimals;
    uint256 public _maxWalletSize = 2000000 * 10 ** _decimals;
    uint256 public _taxSwapThreshold = 500000 * 10 ** _decimals;
    uint256 public _maxTaxSwap = 500000 * 10 ** _decimals;

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

    constructor() {
        _taxWallet = payable(_msgSender());
        _balances[_msgSender()] = _tTotal;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[_taxWallet] = true;

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
        uint256 taxAmount = 0;
        if (from != owner() && to != owner()) {
            taxAmount = amount
                .mul(
                    (_buyCount > _reduceBuyTaxAt)
                        ? _finalBuyTax
                        : _initialBuyTax
                )
                .div(100);

            if (transferDelayEnabled) {
                if (
                    to != address(uniswapV2Router) &&
                    to != address(uniswapV2Pair)
                ) {
                    require(
                        _holderLastTransferTimestamp[tx.origin] < block.number,
                        "_transfer:: Transfer Delay enabled.  Only one purchase per block allowed."
                    );
                    _holderLastTransferTimestamp[tx.origin] = block.number;
                }
            }

            if (
                from == uniswapV2Pair &&
                to != address(uniswapV2Router) &&
                !_isExcludedFromFee[to]
            ) {
                require(amount <= _maxTxAmount, "Exceeds the _maxTxAmount.");
                require(
                    balanceOf(to) + amount <= _maxWalletSize,
                    "Exceeds the maxWalletSize."
                );
                _buyCount++;
            }

            if (to == uniswapV2Pair && from != address(this)) {
                taxAmount = amount
                    .mul(
                        (_buyCount > _reduceSellTaxAt)
                            ? _finalSellTax
                            : _initialSellTax
                    )
                    .div(100);
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
                if (contractETHBalance > 50000000000000000) {
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
        transferDelayEnabled = false;
        emit MaxTxAmountUpdated(_tTotal);
    }

    function sendETHToFee(uint256 amount) private {
        _taxWallet.transfer(amount);
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