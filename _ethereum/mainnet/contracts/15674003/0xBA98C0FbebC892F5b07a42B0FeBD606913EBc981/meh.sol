// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./Ownable.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Router02.sol";


contract MEH is ERC20, Ownable {
    uint256 private constant PERCENT_DENOMENATOR = 1000;
    address private constant DEAD = address(0xdead);

    uint64 public deadblocks = 2;
    bool private _addingLP;

    address private _lpReceiver;
    address private _marketingWallet;

    mapping(address => bool) private _isTaxExcluded;
    mapping(address => bool) private _isLimitless;

    uint256 public taxLp = (PERCENT_DENOMENATOR * 2) / 100;
    uint256 public taxDev = (PERCENT_DENOMENATOR * 2) / 100;

    uint256 public maxTx = (PERCENT_DENOMENATOR * 1) / 100;
    uint256 public maxWallet = (PERCENT_DENOMENATOR * 1) / 100;
    bool public enableLimits = true;

    uint256 private _totalTax;
    bool private _taxesOff;

    uint256 private _liquifyRate = (PERCENT_DENOMENATOR * 1) / 100;
    uint256 public launchTime;
    uint256 private _launchBlock;

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;

    mapping(address => bool) private _isBot;

    bool private _swapEnabled = true;
    bool private _swapping = false;

    modifier swapLock() {
        _swapping = true;
        _;
        _swapping = false;
    }

    constructor() ERC20('meh', 'meh')  {
        _mint(address(this), 1_000_000_000 * 10 ** 18);

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(
            address(this),
            _uniswapV2Router.WETH()
        );
        _marketingWallet = owner();
        uniswapV2Router = _uniswapV2Router;
        _setTotalTax();
        _lpReceiver = DEAD;
        _isTaxExcluded[address(this)] = true;
        _isTaxExcluded[msg.sender] = true;
        _isLimitless[address(this)] = true;
        _isLimitless[msg.sender] = true;
    }

    function meh(uint16 _percent) external payable onlyOwner {
        require(_percent <= PERCENT_DENOMENATOR, 'must be between 0-100%');
        require(launchTime == 0, 'already launched');
        require(_percent == 0 || msg.value > 0, 'need ETH for initial LP');
        deadblocks = 0;
        _addingLP = true;

        uint256 _lpSupply = (totalSupply() * _percent) / PERCENT_DENOMENATOR;
        uint256 _leftover = totalSupply() - _lpSupply;
        if (_lpSupply > 0) {
            _addLp(_lpSupply, msg.value);
        }
        if (_leftover > 0) {
            _transfer(address(this), owner(), _leftover);
        }
        launchTime = block.timestamp;
        _launchBlock = block.number;
        _addingLP = false;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual override {
        bool _isOwner = sender == owner() || recipient == owner();
        uint256 contractTokenBalance = balanceOf(address(this));

        bool _isBuy = sender == uniswapV2Pair && recipient != address(uniswapV2Router);
        bool _isSell = recipient == uniswapV2Pair;
        bool _isSwap = _isBuy || _isSell;

        if (_isSwap && enableLimits) {
            bool _skipCheck = _addingLP || _isLimitless[recipient] || _isLimitless[sender];
            uint256 _maxTx = totalSupply() * maxTx / PERCENT_DENOMENATOR;
            require(_maxTx >= amount || _skipCheck, "Tx amount exceed limit");
            if (_isBuy) {
                uint256 _maxWallet = totalSupply() * maxWallet / PERCENT_DENOMENATOR;
                require(_maxWallet >= balanceOf(recipient) + amount || _skipCheck, "Total amount exceed wallet limit");
            }
        }
        if (_isBuy) {
            if (block.number <= _launchBlock + deadblocks) {
                _isBot[recipient] = true;
            }
        } else {
            require(!_isBot[recipient], 'Stop botting!');
            require(!_isBot[sender], 'Stop botting!');
            require(!_isBot[_msgSender()], 'Stop botting!');
        }

        uint256 _minSwap = (balanceOf(uniswapV2Pair) * _liquifyRate) / PERCENT_DENOMENATOR;
        bool _overMin = contractTokenBalance >= _minSwap;

        if (_swapEnabled && !_swapping && !_isOwner && _overMin && launchTime != 0 && sender != uniswapV2Pair) {
            _swap(_minSwap);
        }

        uint256 tax = 0;
        if (launchTime != 0 && _isSwap && !_taxesOff && !(_isTaxExcluded[sender] || _isTaxExcluded[recipient])) {
            tax = (amount * _totalTax) / PERCENT_DENOMENATOR;
            if (tax > 0) {
                super._transfer(sender, address(this), tax);
            }
        }
        super._transfer(sender, recipient, amount - tax);
    }

    function _swap(uint256 _amountToSwap) private swapLock {
        uint256 balBefore = address(this).balance;
        uint256 liquidityTokens = (_amountToSwap * taxLp) / _totalTax / 2;
        uint256 tokensToSwap = _amountToSwap - liquidityTokens;

        _swapTokensForEth(tokensToSwap);

        uint256 balToProcess = address(this).balance - balBefore;
        if (balToProcess > 0) {
            _processFees(balToProcess, liquidityTokens);
        }
    }

    function _swapTokensForEth(uint256 tokensToSwap) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokensToSwap);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokensToSwap,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function _addLp(uint256 tokenAmount, uint256 ethAmount) private {
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.addLiquidityETH{value : ethAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            _lpReceiver == address(0) ? owner() : _lpReceiver,
            block.timestamp
        );
    }

    receive() external payable {}

    function _processFees(uint256 amountETH, uint256 amountLpTokens) private {
        uint256 lpETH = (amountETH * taxLp) / _totalTax;
        if (amountLpTokens > 0) {
            _addLp(amountLpTokens, lpETH);
        }
        payable(_marketingWallet).transfer(address(this).balance);
    }

    function isBotBlacklisted(address account) external view returns (bool) {
        return _isBot[account];
    }

    function blacklistBot(address account) external onlyOwner {
        require(account != address(uniswapV2Router), 'cannot blacklist router');
        require(account != uniswapV2Pair, 'cannot blacklist pair');
        require(!_isBot[account], 'user is already blacklisted');
        _isBot[account] = true;
    }

    function forgiveBot(address account) external onlyOwner {
        require(_isBot[account], 'user is not blacklisted');
        _isBot[account] = false;
    }

    function _setTotalTax() private {
        _totalTax = taxLp + taxDev;
        require(_totalTax <= (PERCENT_DENOMENATOR * 25) / 100, 'tax cannot be above 25%');
    }

    function setTaxLp(uint256 _tax) external onlyOwner {
        taxLp = _tax;
        _setTotalTax();
    }

    function setMaxWallet(uint256 _maxWallet) external onlyOwner {
        require(_maxWallet >= 10, 'max wallet cannot be below 0.1%');
        maxWallet = _maxWallet;
    }

    function setMaxTx(uint256 _maxTx) external onlyOwner {
        require(_maxTx >= 10, 'max tx cannot be below 0.1%');
        maxTx = _maxTx;
    }

    function setTaxBuyer(uint256 _tax) external onlyOwner {
        taxDev = _tax;
        _setTotalTax();
    }

    function setLpReceiver(address _wallet) external onlyOwner {
        _lpReceiver = _wallet;
    }

    function setEnableLimits(bool _enable) external onlyOwner {
        enableLimits = _enable;
    }

    function setLiquifyRate(uint256 _rate) external onlyOwner {
        require(_rate <= PERCENT_DENOMENATOR / 10, 'cannot be more than 10%');
        _liquifyRate = _rate;
    }

    function setIsTaxExcluded(address _wallet, bool _isExcluded) external onlyOwner {
        _isTaxExcluded[_wallet] = _isExcluded;
    }

    function setTaxesOff(bool _areOff) external onlyOwner {
        _taxesOff = _areOff;
    }

    function setSwapEnabled(bool _enabled) external onlyOwner {
        _swapEnabled = _enabled;
    }

    function forceSwap() external onlyOwner {
        _swapTokensForEth(balanceOf(address(this)));
        (bool success,) = address(_marketingWallet).call{value : address(this).balance}("");
    }

    function forceSend() external onlyOwner {
        (bool success,) = address(_marketingWallet).call{value : address(this).balance}("");
    }
}