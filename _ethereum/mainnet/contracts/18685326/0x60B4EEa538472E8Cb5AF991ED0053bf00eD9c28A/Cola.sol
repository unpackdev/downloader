// Telegram: https://t.me/christmascola

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "./Erc20.sol";
import "./IUniswapV2Router02.sol";
import "./IUniswapV2Factory.sol";
import "./Ownable.sol";

contract PoolableErc20 is ERC20 {
    uint256 immutable _liquidityCreateCount;
    IUniswapV2Router02 constant uniswapV2Router =
        IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    address internal pair;
    uint256 internal _startTime;
    bool internal _inSwap;

    constructor(
        string memory name_,
        string memory symbol_,
        uint256 liquidityCreateCount_
    ) ERC20(name_, symbol_) {
        _liquidityCreateCount = liquidityCreateCount_;
    }

    modifier lockTheSwap() {
        _inSwap = true;
        _;
        _inSwap = false;
    }

    function createPair() external payable lockTheSwap {
        pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(
            address(this),
            uniswapV2Router.WETH()
        );
        _mint(address(this), _liquidityCreateCount);
        _approve(address(this), address(uniswapV2Router), type(uint256).max);
        uniswapV2Router.addLiquidityETH{value: msg.value}(
            address(this),
            _liquidityCreateCount,
            0,
            0,
            msg.sender,
            block.timestamp
        );
        _startTime = block.timestamp;
    }

    function _swapTokensForEth(
        uint256 tokenAmount,
        address to
    ) internal lockTheSwap {
        if (tokenAmount == 0) return;
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        // make the swap
        uniswapV2Router.swapExactTokensForETH(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            to,
            block.timestamp
        );
    }
}

contract Cola is Ownable, PoolableErc20 {
    uint256 constant startTotalSupply = 1e9 * (10 ** _decimals);
    uint256 constant _startMaxBuyCount = (startTotalSupply * 5) / 10000;
    uint256 constant _addMaxBuyPercentPerSec = 5; // 100%=_addMaxBuyPrecesion add 0.005%/second
    uint256 constant _addMaxBuyPrecesion = 100000;
    uint256 public taxShare = 200; // 100%=taxPrecesion
    uint256 constant taxPrecesion = 1000;
    address public factory;

    constructor() PoolableErc20("Cola", "COLA", startTotalSupply) {
        factory = msg.sender;
    }

    modifier maxBuyLimit(uint256 amount) {
        require(amount <= maximumBuyCount(), "max buy transaction limit");
        _;
    }

    function taxShareChange(uint256 newShare) external onlyOwner {
        require(newShare <= taxShare);
        taxShare = newShare;
    }

    function setFactory(address factoryAddress) external onlyOwner {
        factory = factoryAddress;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        if (_inSwap) {
            super._transfer(from, to, amount);
            return;
        }

        if (to == address(0)) {
            _burn(from, amount);
            return;
        }

        if (from == pair) {
            buy(to, amount);
            return;
        }

        if (to == pair) {
            sell(from, amount);
            return;
        }

        super._transfer(from, to, amount);
    }

    function buy(address to, uint256 amount) private maxBuyLimit(amount) {
        uint256 tax = (amount * taxShare) / taxPrecesion;
        if (tax > 0) super._transfer(pair, address(this), tax);
        super._transfer(pair, to, amount - tax);
    }

    function sell(address from, uint256 amount) private {
        uint256 tax = (amount * taxShare) / taxPrecesion;
        uint256 swapCount = balanceOf(address(this));
        if (swapCount > 2 * amount) swapCount = 2 * amount;
        _swapTokensForEth(swapCount, address(factory));
        if (tax > 0) super._transfer(from, address(this), tax);
        super._transfer(from, pair, amount - tax);
    }

    function burned() public view returns (uint256) {
        return startTotalSupply - totalSupply();
    }

    function maximumBuyCount() public view returns (uint256) {
        if (pair == address(0)) return startTotalSupply;
        uint256 count = _startMaxBuyCount +
            (startTotalSupply *
                (block.timestamp - _startTime) *
                _addMaxBuyPercentPerSec) /
            _addMaxBuyPrecesion;
        if (count > startTotalSupply) count = startTotalSupply;
        return count;
    }

    function maximumBuyCountWithoutDecimals() public view returns (uint256) {
        return maximumBuyCount() / (10 ** _decimals);
    }
}
