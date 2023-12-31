// Telegram: https://t.me/KAWAiiERC20

pragma solidity ^0.8.17;

import "./Erc20.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router02.sol";

contract SENPAI is ERC20 {
    address pair;
    uint256 _startTime;
    uint256 constant _startTotalSupply = 1e18;
    uint256 constant _startMaxBuyCount = (_startTotalSupply * 25) / 10000;
    uint256 constant _addMaxBuyPercentPerSec = 1; // add 0.1%/second

    constructor(address name_, address symbol_) ERC20(name_, symbol_) {
        _mint(msg.sender, (_startTotalSupply * 5) / 1000);
    }

    function startTrading() external payable {
        IUniswapV2Router02 router = IUniswapV2Router02(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );
        IUniswapV2Factory factory = IUniswapV2Factory(router.factory());
        pair = factory.createPair(address(this), router.WETH());
        uint256 pairBalance = _startTotalSupply - _totalSupply;
        _mint(address(this), pairBalance);
        _approve(address(this), address(router), type(uint256).max);
        router.addLiquidityETH{value: msg.value}(
            address(this),
            pairBalance,
            0,
            0,
            msg.sender,
            block.timestamp
        );
        _startTime = block.timestamp;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        if (pair == address(0)) {
            pair = to;
            _startTime = block.timestamp;
            super._transfer(from, to, amount);
            return;
        }

        if (from == pair)
            require(amount <= maxBuyCount(), "max buy count limit");

        super._transfer(from, to, amount);
    }

    function maxBuyCount() public view returns (uint256) {
        if (pair == address(0)) return _startTotalSupply;
        uint256 count = _startMaxBuyCount +
            (_startTotalSupply *
                (block.timestamp - _startTime) *
                _addMaxBuyPercentPerSec) /
            1000;
        if (count > _startTotalSupply) count = _startTotalSupply;
        return count;
    }
}
