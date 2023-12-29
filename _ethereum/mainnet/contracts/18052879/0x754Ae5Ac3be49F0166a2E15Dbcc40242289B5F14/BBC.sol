// SPDX-License-Identifier: MIT

/*
  /$$$$$$$  /$$$$$$$   /$$$$$$ 
| $$__  $$| $$__  $$ /$$__  $$
| $$  \ $$| $$  \ $$| $$  \__/
| $$$$$$$ | $$$$$$$ | $$      
| $$__  $$| $$__  $$| $$      
| $$  \ $$| $$  \ $$| $$    $$
| $$$$$$$/| $$$$$$$/|  $$$$$$/
|_______/ |_______/  \______/ 

 Community-Driven IDO Launchpad

 Website: https://bbclub.vip
 Twitter: https://x.com/bbclub_vip
 Telegram: https://t.me/bbclub_vip
*/

pragma solidity ^0.8.20;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./Ownable.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router02.sol";

contract BBC is ERC20, ERC20Burnable, Ownable {

    mapping (address => bool) private _isExcludedFromFee;
    mapping(address => uint256) private _holderLastTransferTimestamp;

    address private _taxWallet = address(0xbab0c54eC11AE961bdDa40Ce58E4F2a9D99FB3DE);
    uint256 public _buyTax = 1;
    uint256 public _sellTax = 3;
    uint256 public _maxSupply = 1e9 * 10 ** decimals();
    uint256 public _maxTxAmount =   1e7 * 10 ** decimals();
    uint256 public _maxWalletSize = 2e7 * 10 ** decimals();
    uint256 public _taxSwapThreshold = 1e5 * 10 ** decimals();
    uint256 public _maxTaxSwap = 5e6 * 10 ** decimals();
    bool public _transferDelayEnabled = true;

    IUniswapV2Router02 public swapRouter;
    address public swapPair;

    constructor() ERC20("Billionaire Blockchain Club", "BBC") {

        _mint(msg.sender, (_maxSupply));

        IUniswapV2Router02 _uniswapRouter = IUniswapV2Router02(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );
        swapPair = IUniswapV2Factory(_uniswapRouter.factory())
            .createPair(address(this), _uniswapRouter.WETH());

        swapRouter = _uniswapRouter;

        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[address(0xdead)] = true;

        _approve(address(this), address(swapRouter), type(uint256).max);
    }

    function removeLimits() external onlyOwner {
        _maxTxAmount = _maxSupply;
        _maxWalletSize = _maxSupply;
        _transferDelayEnabled = false;
    }

    function min(uint256 a, uint256 b) private pure returns (uint256) {
      return (a > b) ? b : a;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {

        uint256 taxAmount = 0;

        if (!_isExcludedFromFee[from] && !_isExcludedFromFee[to]) {

            if (_transferDelayEnabled) {
                if (to != address(swapRouter) && to != address(swapPair)) {
                  require(_holderLastTransferTimestamp[tx.origin] < block.number,"Only one transfer per block allowed.");
                  _holderLastTransferTimestamp[tx.origin] = block.number;
                }
            }

            if (from == swapPair && to != address(swapRouter)) {
                require(amount <= _maxTxAmount, "Exceeds the _maxTxAmount.");
                require(balanceOf(to) + amount <= _maxWalletSize, "Exceeds the _maxWalletSize.");
                taxAmount = uint256((amount * _buyTax) / 100);
            }

            if (to == swapPair) {
                taxAmount = uint256((amount * _sellTax) / 100);
                uint256 tokenBalance = balanceOf(address(this));
                if (tokenBalance > _taxSwapThreshold) {
                    swapTokensForEth(min(tokenBalance, _maxTaxSwap));
                    uint256 ethBalance = address(this).balance;
                    if (ethBalance > 0) {
                        (bool sent,) = payable(_taxWallet).call{value: ethBalance}("");
                        require(sent, "Failed to send Ether");
                    }
                }
            }

            if (taxAmount > 0) {
                super._transfer(from, address(this), taxAmount);
            }
        }
        super._transfer(from, to, amount - taxAmount);
    }

    function swapTokensForEth(uint256 _taxAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = swapRouter.WETH();
        swapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            _taxAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function manualSwap() external {
        require(msg.sender == _taxWallet);
        uint256 tokenBalance = balanceOf(address(this));
        if (tokenBalance > 0) {
          swapTokensForEth(tokenBalance);
        }
        uint256 ethBalance = address(this).balance;
        if (ethBalance > 0) {
          (bool sent,) = payable(_taxWallet).call{value: ethBalance}("");
           require(sent, "Failed to send Ether");
        }
    }

    receive() external payable {}
}