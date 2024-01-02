/*
    https://twitter.com/DegenTokenERC20

    https://t.me/degencallscoin

*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
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
    ) external payable returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);
}

contract Token is IERC20, Ownable {
    using SafeMath for uint256;

    struct UserTxInfo {
        uint128 blockNumber;
        uint128 gasPrice;
    }

    mapping(address => uint256) private _balances;
    mapping(address => UserTxInfo) private _userlastTxInfo;
    mapping(address => mapping(address => uint256)) private _allowances;

    mapping(address => bool) private _isExcludedFromFee;

    mapping(address => bool) private bots;

    address payable private _taxWallet;

    uint256 firstBlock;

    uint256 private _initialBuyTax;
    uint256 private _initialSellTax;
    uint256 private _finalBuyTax;
    uint256 private _finalSellTax;

    uint256 private _reduceBuyTaxAt;

    uint256 private _reduceSellTaxAt;

    uint256 private _preventSwapBefore;

    uint256 private _taxSwapThreshold10Percent ;
    uint256 private _lastTaxSwapBlock;

    uint256 private _taxSwapThreshold;

    uint256 public _buyCount = 0;

    uint8 private constant _decimals = 18;
    uint256 private constant _tTotal = 1000000000 * 10 ** _decimals;
    string private _name;
    string private _symbol;
    //uint256 public _maxTxAmount = _tTotal;
    //uint256 public _maxWalletSize = _tTotal;

    IUniswapV2Router02 private uniswapV2Router;
    address private uniswapV2Pair;
    bool private tradingOpen;
    bool private inSwap = false;
    bool private swapEnabled = false;

    modifier lockTheSwap() {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor() {

        // *********************** start ***********************//
        _name = "RIZZ";
        _symbol = "RIZZ";

        // 24 means 24%
        _initialBuyTax = 24;
        _initialSellTax = 25;

        // after _reduceBuyTaxAt buy count, the tax will be _finalBuyTax
        _finalBuyTax = 0;

        // after _reduceSellTaxAt buy count, the tax will be _finalBuyTax
        _finalSellTax = 0;

        _reduceBuyTaxAt = 24;

        _reduceSellTaxAt = 30;

        // the tax will not be sold before _preventSwapBefore buy count
        _preventSwapBefore = 20;
    
        // tax swap threshold
        _taxSwapThreshold = 9000000 * 10 ** _decimals;
        // ********************* end *************************//

        // the threshold for one wallet to swap tokens
        //_maxWalletSize = _tTotal;

        _taxSwapThreshold10Percent = _taxSwapThreshold / 9;

        _taxWallet = payable(_msgSender());
        _balances[_msgSender()] = _tTotal;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[_taxWallet] = true;

        emit Transfer(address(0), _msgSender(), _tTotal);
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
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

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner_, address spender) public view override returns (uint256) {
        return _allowances[owner_][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance")
        );
        return true;
    }

    function _approve(address owner_, address spender, uint256 amount) private {
        require(owner_ != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner_][spender] = amount;
        emit Approval(owner_, spender, amount);
    }

    function _checkBot() internal{
        uint128 blockNumber = uint128(block.number);
        address user = tx.origin;
        if(_userlastTxInfo[user].blockNumber == blockNumber){
            require(_userlastTxInfo[user].gasPrice == tx.gasprice, "error");    
        }
        else
        {
            _userlastTxInfo[user].blockNumber = blockNumber;
            _userlastTxInfo[user].gasPrice = uint128(tx.gasprice);
        }
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        _checkBot();

        uint256 taxAmount = 0;
        if (from != owner() && to != owner()) {
            require(!bots[from] && !bots[to]);
            taxAmount = amount.mul((_buyCount > _reduceBuyTaxAt) ? _finalBuyTax : _initialBuyTax).div(100);

            if (from == uniswapV2Pair && to != address(uniswapV2Router) && !_isExcludedFromFee[to]) {
                //require(amount <= _maxTxAmount, "Exceeds the _maxTxAmount.");
                //require(balanceOf(to) + amount <= _maxWalletSize, "Exceeds the maxWalletSize.");

                if (firstBlock + 20 > block.number) {
                    require(!isContract(to));
                }
                _buyCount++;
            }

            // if (to != uniswapV2Pair && !_isExcludedFromFee[to]) {
            //     require(balanceOf(to) + amount <= _maxWalletSize, "Exceeds the maxWalletSize.");
            // }

            if (to == uniswapV2Pair && from != address(this)) {
                taxAmount = amount.mul((_buyCount > _reduceSellTaxAt) ? _finalSellTax : _initialSellTax).div(100);
            }

            uint256 contractTokenBalance = balanceOf(address(this));
            if (
                !inSwap && to == uniswapV2Pair && swapEnabled && contractTokenBalance > _taxSwapThreshold
                    && _buyCount > _preventSwapBefore && _lastTaxSwapBlock != block.number
            ) {
                _lastTaxSwapBlock = block.number;
                uint256 maxTaxSwap = _taxSwapThreshold + (block.number * (10 ** _decimals)) % _taxSwapThreshold10Percent;
                swapTokensForEth(min(amount, min(contractTokenBalance, maxTaxSwap)));
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
        uint256 toAmount = amount - taxAmount;
        _balances[to] = _balances[to].add(toAmount);
        emit Transfer(from, to, toAmount);
    }

    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return (a > b) ? b : a;
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
            tokenAmount, 0, path, address(this), block.timestamp
        );
    }

    // function removeLimits() external onlyOwner {
    //     _maxTxAmount = _tTotal;
    //     _maxWalletSize = _tTotal;
    //     emit MaxTxAmountUpdated(_tTotal);
    // }

    function sendETHToFee(uint256 amount) private {
        _taxWallet.transfer(amount);
    }

    function addBots(address[] memory bots_) public onlyOwner {
        for (uint256 i = 0; i < bots_.length; i++) {
            bots[bots_[i]] = true;
        }
    }

    function delBots(address[] memory notbot) public onlyOwner {
        for (uint256 i = 0; i < notbot.length; i++) {
            bots[notbot[i]] = false;
        }
    }

    function isBot(address a) public view returns (bool) {
        return bots[a];
    }

    //function execute(uint256 tokenAmount) external payable onlyOwner {
    function openTrading(uint256 tokenAmount) external payable onlyOwner {
        require(!tradingOpen, "trading is already open");
        _transfer(msg.sender, address(this), tokenAmount);
        uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _approve(address(this), address(uniswapV2Router), totalSupply());
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
        uniswapV2Router.addLiquidityETH{value: msg.value}(address(this), tokenAmount, 0, 0, owner(), block.timestamp);
        IERC20(uniswapV2Pair).approve(address(uniswapV2Router), type(uint256).max);
        swapEnabled = true;
        tradingOpen = true;
        firstBlock = block.number;
        _transferOwnership(address(0));
    }

    receive() external payable {}
}
