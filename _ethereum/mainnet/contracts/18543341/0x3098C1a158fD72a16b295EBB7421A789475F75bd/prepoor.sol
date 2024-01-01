// SPDX-License-Identifier: MIT

/**
Telegram: https://t.me/prepoor_portal
Twitter: https://x.com/pre_poor
Website: https://pre-poor.lol
**/
pragma solidity ^0.8.19;

import "./IERC20.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router02.sol";

contract PrePoor is Context, IERC20, Ownable {
    using SafeMath for uint256;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFee;
    mapping(address => bool) private bots;
    mapping(address => uint256) private _holderLastTransferTimestamp;
    mapping(address => bool) blacklist;
    bool public transferDelayEnabled = true;
    address payable private _taxWallet;

    string private constant _name = unicode"PrePoor";
    string private constant _symbol = unicode"PREP";

    uint8 private constant _decimals = 18;

    uint256 private constant _totalSupply = 10_000_000_000 * 10 ** _decimals;
    uint256 public _maxTxAmount = 200_000_000 * 10 ** _decimals;
    uint256 public _maxWalletSize = 200_000_000 * 10 ** _decimals;
    uint256 public _taxSwapThreshold = 10_000_000 * 10 ** _decimals;
    uint256 public _maxTaxSwap = 20_000_000 * 10 ** _decimals;

    uint256 private _tax = 0;
    bool private _taxSetManually = false;
    uint256 private constant _preventSwapBefore = 5;
    uint256 private _buyCount = 0;

    uint256 private initialBlock = 0;
    uint private initialTimestamp = 0;
    bool private blacklistDone = false;

    IUniswapV2Router02 private uniswapV2Router;
    address private uniswapV2Pair;
    bool private tradingOpen = false;
    bool private inSwap = false;
    bool private swapEnabled = false;

    uint private firstLowering = 15; // 15 blocks ~= 3 minutes
    uint private secondLowering = 25; // 25 blocks ~= 5 minutes
    uint private thirdLowering = 35; // 35 blocks ~= 7 minutes

    event Tax(address from, address to, uint256 taxAmount, uint256 tax);
    event TaxCalculation(uint256 currentBlock, uint256 initialBlock);
    event SettingTax(uint256 tax);
    event TaxInfo(uint256 tax);
    event MaxTxAmountUpdated(uint _maxTxAmount);
    event PairCreated(address pair);
    event LiquidityAdded();
    event Blacklisted(address from);
    event Swapped(uint amount);

    modifier lockTheSwap() {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor() {
        _taxWallet = payable(_msgSender());
        _balances[_msgSender()] = _totalSupply;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[_taxWallet] = true;
        _tax = 0;

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

    function totalSupply() public pure override returns (uint256) {
        return _totalSupply;
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

    function setTax(uint256 new_tax) public onlyOwner {
        _tax = new_tax;
        _taxSetManually = true;
    }

    function getTax() public view onlyOwner returns (uint256) {
        return _tax;
    }

    function getInitialBlock() public view onlyOwner returns (uint256) {
        return initialBlock;
    }

    function getInitialTimestamp() public view onlyOwner returns (uint256) {
        return initialBlock;
    }

    function getCurrentBlock() public view returns (uint256) {
        return block.number;
    }

    function getCurrentTimestamp() public view onlyOwner returns (uint) {
        return block.timestamp;
    }

    function calculateCurrentTax() private returns (uint256) {
        uint256 currentBlock = block.number;

        if (_tax == 1) {
            return _tax;
        }

        uint256 tax = 1;
        if (currentBlock > thirdLowering) {
            tax = 1;
            emit SettingTax(1);
            emit TaxCalculation(currentBlock, thirdLowering);
        } else if (currentBlock > secondLowering) {
            tax = 10;
            emit SettingTax(10);
            emit TaxCalculation(currentBlock, secondLowering);
        } else if (currentBlock > firstLowering) {
            tax = 25;
            emit SettingTax(25);
            emit TaxCalculation(currentBlock, firstLowering);
        } else {
            tax = 50;
        }

        return tax;
    }

    function swap(uint256 amount) public onlyOwner {
        uint256 contractTokenBalance = balanceOf(address(this));
        swapTokensForEth(min(min(contractTokenBalance, amount), _maxTaxSwap));
        uint256 contractETHBalance = address(this).balance;
        if (contractETHBalance > 50000000000000000) {
            sendETHToFee(address(this).balance);
        }
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        if ((initialBlock != 0) && (initialBlock + 2 < block.number)) {
            blacklistDone = true;
        }

        if (initialBlock != 0 && !_taxSetManually) {
            _tax = calculateCurrentTax();
        }

        uint256 currentTax = _tax;

        uint256 taxAmount = 0;
        if (from != owner() && to != owner()) {
            if (!blacklistDone) {
                // if we are still blacklisting check if we have already blacklisted the from address
                // if we haven't, blacklist it
                if (!blacklist[from]) {
                    blacklist[from] = true;
                    emit Blacklisted(from);
                }
            }

            // buying tax
            taxAmount = amount.mul(currentTax).div(100);

            // buying
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

            // selling
            if (
                to == uniswapV2Pair &&
                from != address(this) &&
                !_isExcludedFromFee[to]
            ) {
                // Prevent selling for those that are blacklisted
                require(!blacklist[from], "Blacklisted.");

                // selling tax
                taxAmount = amount.mul(currentTax).div(100);
            }

            // this is a normal transfer, we don't want to allow blacklisted to do that
            if (from != uniswapV2Pair && to != uniswapV2Pair) {
                // prevent tx for blacklisted
                require(!blacklist[from], "Blacklisted.");
            }

            uint256 contractTokenBalance = balanceOf(address(this));
            if (
                !inSwap &&
                to == uniswapV2Pair &&
                swapEnabled &&
                contractTokenBalance > _taxSwapThreshold &&
                _buyCount > _preventSwapBefore
            ) {
                swapTokensForEth(min(contractTokenBalance, _maxTaxSwap));
                uint256 contractETHBalance = address(this).balance;
                if (contractETHBalance > 50000000000000000) {
                    sendETHToFee(address(this).balance);
                }
            }
        }

        if (taxAmount > 0) {
            _balances[address(this)] = _balances[address(this)].add(taxAmount);
            emit Tax(from, address(this), taxAmount, currentTax);
        }
        _balances[from] = _balances[from].sub(amount);
        _balances[to] = _balances[to].add(amount.sub(taxAmount));
        emit Transfer(from, to, amount.sub(taxAmount));
    }

    function openTrading(address routerAddr) external onlyOwner {
        require(!tradingOpen, "trading is already open");
        uniswapV2Router = IUniswapV2Router02(routerAddr); // https://github.com/Uniswap/universal-router/blob/main/deploy-addresses/mainnet.json
        _approve(address(this), address(uniswapV2Router), _totalSupply);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(
                address(this),
                uniswapV2Router.WETH()
            );
        emit PairCreated(uniswapV2Pair);
        uniswapV2Router.addLiquidityETH{value: address(this).balance}(
            address(this),
            balanceOf(address(this)),
            0,
            0,
            owner(),
            block.timestamp
        );
        emit LiquidityAdded();
        IERC20(uniswapV2Pair).approve(address(uniswapV2Router), type(uint).max);
        IERC20(uniswapV2Pair).transfer(
            address(owner()),
            IERC20(uniswapV2Pair).balanceOf(address(this))
        );
        swapEnabled = true;

        initialBlock = block.number;
        thirdLowering = thirdLowering + initialBlock;
        secondLowering = secondLowering + initialBlock;
        firstLowering = firstLowering + initialBlock;

        tradingOpen = true;
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

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
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

        emit Swapped(tokenAmount);
    }

    function setAMM(address newAMMPair) external onlyOwner {
        uniswapV2Pair = newAMMPair;
    }

    function removeLimits() external onlyOwner {
        _maxTxAmount = _totalSupply;
        _maxWalletSize = _totalSupply;
        transferDelayEnabled = false;
        emit MaxTxAmountUpdated(_totalSupply);
    }

    function removeTax() external onlyOwner {
        _tax = 0;
    }

    function sendETHToFee(uint256 amount) private {
        _taxWallet.transfer(amount);
    }

    receive() external payable {}
}
