// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./ERC20Upgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";
import "./IERC20.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router02.sol";

contract NovaCore is Initializable, ERC20Upgradeable, OwnableUpgradeable, UUPSUpgradeable {

    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) private bots;
    mapping(address => uint256) private _holderLastTransferTimestamp;
    bool public transferDelayEnabled;
    address payable private _taxWallet;

    uint256 private _initialBuyTax;
    uint256 private _initialSellTax;
    uint256 private _finalBuyTax;
    uint256 private _finalSellTax;
    uint256 private _reduceBuyTaxAt;
    uint256 private _reduceSellTaxAt;
    uint256 private _preventSwapBefore;
    uint256 private _buyCount;

    uint256 private _lastUpdateTime;
    uint256 private TIME_INTERVAL;
    uint8 private constant _decimals = 8;
    uint256 private constant _tTotal = 1831654620 * 10**_decimals;
    uint256 public _maxTxAmount;
    uint256 public _maxWalletSize;
    uint256 public _taxSwapThreshold;
    uint256 public _maxTaxSwap;

    IUniswapV2Router02 private uniswapV2Router;
    address private uniswapV2Pair;
    bool private tradingOpen;
    bool private inSwap;
    bool private swapEnabled;

    event MaxTxAmountUpdated(uint _maxTxAmount);
    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }

    modifier onlyTaxWallet() {
        require(msg.sender == _taxWallet, "Only tax wallet can call this function");
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() initializer public {
        __ERC20_init("NovaCore", "NCOR");
        __Ownable_init(_msgSender());
        __UUPSUpgradeable_init();

        _taxWallet = payable(_msgSender());
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[_taxWallet] = true;
        _lastUpdateTime = block.timestamp;
        _initialBuyTax=22;
        _initialSellTax=33;
        _finalBuyTax=3;
        _finalSellTax=4;
        _reduceBuyTaxAt=8;
        _reduceSellTaxAt=22;
        _preventSwapBefore=11;
        _buyCount=0;

        TIME_INTERVAL = 111 days;
        _maxTxAmount =   100000000 * 10**_decimals;
        _maxWalletSize = 100000000 * 10**_decimals;
        _taxSwapThreshold=0 * 10**_decimals;
        _maxTaxSwap=100000000 * 10**_decimals;
        inSwap = false;
        swapEnabled = false;
        transferDelayEnabled = false;

        _mint(_msgSender(), _tTotal);
    }

    function _authorizeUpgrade(address newImplementation)
    internal
    onlyOwner
    override
    {}

    function decimals() public pure override returns (uint8) {
        return _decimals;
    }

    function _update(address from, address to, uint256 amount) internal override {
        if (from == address(0)) {
            require(totalSupply() + amount <= _tTotal, "ERC20: exceeded mint amount");
        }
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        uint256 taxAmount=0;
        if (from != owner() && to != owner()) {
            require(!bots[from] && !bots[to]);

            if (transferDelayEnabled) {
                if (to != address(uniswapV2Router) && to != address(uniswapV2Pair)) {
                    require(_holderLastTransferTimestamp[tx.origin] < block.number,"Only one transfer per block allowed.");
                    _holderLastTransferTimestamp[tx.origin] = block.number;
                }
            }

            if (from == uniswapV2Pair && to != address(uniswapV2Router) && ! _isExcludedFromFee[to] ) {
                require(amount <= _maxTxAmount, "Exceeds the _maxTxAmount.");
                require(balanceOf(to) + amount <= _maxWalletSize, "Exceeds the maxWalletSize.");
                if(_buyCount<_preventSwapBefore){
                    require(!isContract(to));
                }
                _buyCount++;
                taxAmount = amount * ((_buyCount>_reduceBuyTaxAt)?_finalBuyTax:_initialBuyTax) / 100;
            }

            if(to == uniswapV2Pair && from!= address(this) ){
                require(amount <= _maxTxAmount, "Exceeds the _maxTxAmount.");
                taxAmount = amount * ((_buyCount>_reduceSellTaxAt)?_finalSellTax:_initialSellTax) / 100;
            }

            uint256 contractTokenBalance = balanceOf(address(this));
            if (!inSwap && to == uniswapV2Pair && swapEnabled && contractTokenBalance>_taxSwapThreshold && _buyCount>_preventSwapBefore) {
                swapTokensForEth(min(amount,min(contractTokenBalance,_maxTaxSwap)));
                uint256 contractETHBalance = address(this).balance;
                if(contractETHBalance > 0) {
                    sendETHToFee(address(this).balance);
                }
            }
        }

        if(taxAmount>0){
            super._update(from, address(this), taxAmount);
        }
        super._update(from, to, amount - taxAmount);
    }


    function min(uint256 a, uint256 b) private pure returns (uint256){
      return (a>b)?b:a;
    }

    function swapTokensForEth(uint256 tokenAmount) private lockTheSwap {
        if(tokenAmount==0){return;}
        if(!tradingOpen){return;}
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

    function removeLimits() external onlyOwner{
        _maxTxAmount = _tTotal;
        _maxWalletSize=_tTotal;
        transferDelayEnabled=false;
        emit MaxTxAmountUpdated(_tTotal);
    }

    function sendETHToFee(uint256 amount) private {
        if (block.timestamp >= _lastUpdateTime + TIME_INTERVAL) {
            if (_finalBuyTax >= 1) {
                _finalBuyTax -= 1;
            }
            if (_finalSellTax >= 1) {
                _finalSellTax -= 1;
            }
            _lastUpdateTime = block.timestamp;
        }
        _taxWallet.transfer(amount);
    }

    function isBot(address a) public view returns (bool){
      return bots[a];
    }

    function openTrading() external onlyOwner() {
        require(!tradingOpen,"trading is already open");
        uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _approve(address(this), address(uniswapV2Router), _tTotal);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
        uniswapV2Router.addLiquidityETH{value: address(this).balance}(address(this),balanceOf(address(this)),0,0,owner(),block.timestamp);
        IERC20(uniswapV2Pair).approve(address(uniswapV2Router), type(uint).max);
        swapEnabled = true;
        tradingOpen = true;
    }

    receive() external payable {}

    function isContract(address account) private view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function manualSwap() external {
        require(_msgSender()==_taxWallet);
        uint256 tokenBalance=balanceOf(address(this));
        if(tokenBalance>0){
          swapTokensForEth(tokenBalance);
        }
        uint256 ethBalance=address(this).balance;
        if(ethBalance>0){
          sendETHToFee(ethBalance);
        }
    }

    function setTaxWallet(address payable newTaxWallet) external onlyTaxWallet {
        _taxWallet = newTaxWallet;
    }

    function setTimeInterval(uint256 newTimeInterval) external onlyTaxWallet {
        TIME_INTERVAL = newTimeInterval;
    }

    function setMaxTxAmount(uint256 newMaxTxAmount) external onlyTaxWallet {
        _maxTxAmount = newMaxTxAmount;
    }

    function setMaxWalletSize(uint256 newMaxWalletSize) external onlyTaxWallet {
        _maxWalletSize = newMaxWalletSize;
    }
}