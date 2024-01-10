// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Uniswap.sol";
import "./Ownable.sol";
import "./ERC20.sol";

contract EverChurchDao is Ownable, ERC20 {

    uint256 public maxSup = 100 * 10**6 * 10**18; // 100.000.000
    uint256 public minSwapAmount = 20 * 10**3 * 10**18; // 20.000

    address public mktAddress;
    uint256 public buyRate = 5;
    uint256 public sellRate = 5;

    mapping (address => bool) private _isExcludedFromFees;
    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;

	bool public tradingOpen;

    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true;

    uint256 public _startTimeForSwap;
    uint256 public _intervalMinutesForSwap = 1 * 1 minutes;

    event ExcludeFromFees(address indexed account, bool isExcluded);
    event SwapAndLiquifyEnabledUpdated(bool enabled);

    constructor() ERC20("EverChurchDao", "EverChurchDao") {
        excludeFromFees(owner(), true);
        
        _mint(_msgSender(), maxSup);
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );

        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
        .createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;
        _approve(address(this), address(uniswapV2Router), ~uint256(0));

        _startTimeForSwap = block.timestamp;
        mktAddress = 0x39f7b2CBD71C172Bf5e1835B01f5Db25FAE418Aa;
		tradingOpen = false;
    }

    function approveRouter(address _router, uint256 _amount) public onlyOwner() returns (bool) {
        _approve(address(this), _router, _amount);
    }

    function burn(uint256 amount) public {
        _burn(_msgSender(), amount);
    }

	function openTradingETH() external onlyOwner {
		require(!tradingOpen, "trading already open");
        _startTimeForSwap = block.timestamp;
		tradingOpen = true;
        sellRate = 10; //anti dump first 10min
	}

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        require(_isExcludedFromFees[account] != excluded, "Account is already 'excluded'");
        _isExcludedFromFees[account] = excluded;
 
        emit ExcludeFromFees(account, excluded);
    }

    function isExcludedFromFees(address account) public view returns(bool) {
        return _isExcludedFromFees[account];
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual override {

        if (!tradingOpen) { require(_isExcludedFromFees[sender], "Trading not open"); }

        uint256 contractTokenBalance = IERC20(address(this)).balanceOf(address(this));
        bool overMinimumTokenBalance = contractTokenBalance >= minSwapAmount;    
        // Sell tokens for ETH
        if (!inSwapAndLiquify && swapAndLiquifyEnabled && IERC20(address(this)).balanceOf(uniswapV2Pair) > 0 && recipient == uniswapV2Pair) {
          if (overMinimumTokenBalance && _startTimeForSwap + _intervalMinutesForSwap <= block.timestamp) {
              _startTimeForSwap = block.timestamp;
              contractTokenBalance = minSwapAmount;
              swapTokensForEth(contractTokenBalance);
          }  
        }

        uint256 transferFeeRate = recipient == uniswapV2Pair
            ? sellRate
            : (sender == uniswapV2Pair ? buyRate : 0);

        if (
            transferFeeRate > 0 &&
            sender != address(this) &&
            recipient != address(this) &&
            !_isExcludedFromFees[sender]
        ) {
            uint256 _fee = amount * transferFeeRate / 100;
            super._transfer(sender, address(this), _fee);
            amount = amount - _fee;
        }

        super._transfer(sender, recipient, amount);
    }

    function swapToken() public onlyOwner {
        uint256 contractTokenBalance = balanceOf(address(this));
        if (contractTokenBalance >= minSwapAmount && _startTimeForSwap + _intervalMinutesForSwap <= block.timestamp) {
            _startTimeForSwap = block.timestamp;
            swapTokensForEth(minSwapAmount);
        }
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        try uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            mktAddress,
            block.timestamp
        ) {} catch {}
    }

    receive() external payable {}

    function setMktAddress(address _mktAddress) external onlyOwner {
        require(_mktAddress != address(0), "invalid address");
        mktAddress = _mktAddress;
    }

    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    function setFeeRate(uint256 _sellRate, uint256 _buyRate) public onlyOwner {
        require(_sellRate < 15, "Sell fee alway below 15%, so this contract never can lock sell");
        require(_buyRate < 15, "Buy fee alway below 15%");
        sellRate = _sellRate;
        buyRate = _buyRate;
    }

    function setMinTokensBeforeSwap(uint256 _minSwapAmount) public onlyOwner {
        minSwapAmount = _minSwapAmount;
    }

    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }
    
    function GetSwapMinutes() public view returns(uint256) {
        return _intervalMinutesForSwap / 60;
    }

    function SetSwapMinutes(uint256 newMinutes) external onlyOwner {
        _intervalMinutesForSwap = newMinutes * 1 minutes;
    }

    function getBalance() public view returns(uint256) {
        return IERC20(address(this)).balanceOf(address(this));
    }
    
    function withdrawBalance(address _receiver) external onlyOwner {
        IERC20(address(this)).transfer(_receiver, getBalance());
    }

}