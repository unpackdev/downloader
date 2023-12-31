/*

TELEGRAM: https://t.me/KepePortal
TWITTER:  https://twitter.com/Kingpeperc
WEBSITE:  https://kingpepecoin.com/

*/

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC20.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router02.sol";

contract KEPE is ERC20, Ownable {

    IUniswapV2Router02 public immutable uniswapV2Router;
    address public immutable uniswapV2Pair;
    uint256 public mintAmount = 420_690_000_000_000 * 10 ** decimals();
    uint256 public maxSwapAmount = mintAmount / 500;
    uint256 public maxHoldingAmount = mintAmount / 100;
    uint256 public swapTokensAtAmount = mintAmount / 1000;
    uint256 public buybps = 0;
    uint256 public sellbps = 0;
    bool public swapEnabled = true;
    bool public inSwapBack = false;
    bool public trading = false;
    bool public limitOn = true;

    mapping(address => bool) public blacklist;

    constructor() ERC20("KingPepe", "KEPE") {
        uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
        _mint(msg.sender, mintAmount);
    }

    receive() external payable {}

    function setBlacklist(address _address, bool _isBlacklisted) external onlyOwner {
        blacklist[_address] = _isBlacklisted;
    }

    function setRule(bool _trade, bool _limitOn, uint256 _maxHoldingAmount, uint256 _buyBps, uint256 _sellBps) external onlyOwner {
        trading = _trade;
        limitOn = _limitOn;
        maxHoldingAmount = _maxHoldingAmount;
        buybps = _buyBps;
        sellbps = _sellBps;
    }

    function _transfer(address from, address to, uint256 amount) internal override {
        require(!blacklist[to] && !blacklist[from]);
        if (!trading) {
            require(from == owner() || to == owner());
        } else {
            if (limitOn && from == uniswapV2Pair) {
                require(super.balanceOf(to) + amount <= maxHoldingAmount);
            }
        }

        uint256 swapAmount = super.balanceOf(address(this));
        bool isBuy = (from == uniswapV2Pair);
        bool isSell = (to == uniswapV2Pair);
        bool canSwap = swapAmount >= swapTokensAtAmount;

        if (!inSwapBack && canSwap && swapEnabled && isSell) {
            inSwapBack = true;

            if (swapAmount > maxSwapAmount) {
              swapAmount = maxSwapAmount;
            }
            swapBack(swapAmount / 2 - 1);

            inSwapBack = false;
        }

        if (!inSwapBack) {
            if (isSell) {
                uint256 fees = amount * sellbps / 10000;
                super._transfer(from, address(this), fees);
                amount -= fees;
            } else if (isBuy) {
          	    uint256 fees = amount * buybps / 10000;
                super._transfer(from, address(this), fees);
                amount -= fees;
            }
        }

        super._transfer(from, to, amount);
    }

    function swapTokensForEth(uint256 tokenAmount) private {

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        if (allowance(address(this), address(uniswapV2Router)) < tokenAmount) {
            _approve(address(this), address(uniswapV2Router), 2**256-1);
        }

        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {

        if (allowance(address(this), address(uniswapV2Router)) < tokenAmount) {
            _approve(address(this), address(uniswapV2Router), 2**256-1);
        }

        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            address(0xdead),
            block.timestamp
        );
    }

    function swapBack(uint256 amount) private {
        swapTokensForEth(amount);
        addLiquidity(amount, address(this).balance);
    }
}
