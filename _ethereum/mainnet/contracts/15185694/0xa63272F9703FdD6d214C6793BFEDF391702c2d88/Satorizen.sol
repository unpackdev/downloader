//SPDX-License-Identifier: MIT
/*
         69696969                         69696969
       6969    696969                   696969    6969
     969    69  6969696               6969  6969     696
    969        696969696             696969696969     696
   969        69696969696           6969696969696      696
   696      9696969696969           969696969696       969
    696     696969696969             969696969        969
     696     696  96969      _=_      9696969  69    696
       9696    969696      q(-_-)p      696969    6969
          96969696         '_) (_`         69696969
             96            /__/  \            69
             69          _(<_   / )_          96
            6969        (__\_\_|_/__)        9696

                lightweight relaxed erc20 coin
*/

pragma solidity ^0.8.5;

import "./IUniswapV2Pair.sol";

import "./IUniswapV2Factory.sol";

import "./IUniswapV2Router02.sol";

import "./ERC20.sol";
import "./Ownable.sol";

contract Satorizen is ERC20, Ownable {
    string constant _name = "Satorizen";
    string constant _symbol = "STRZ";

    uint256 fee = 2;

    address DEAD = 0x000000000000000000000000000000000000dEaD;
    mapping(address => bool) isTxLimitExempt;
    IUniswapV2Router02 public rt;
    address public pair;

    uint256 _totalSupply = 1000000000 * (10**decimals());
    uint256 public _maxWalletAmount = (_totalSupply * 4) / 100;
    mapping(address => bool) isFeeExempt;

    bool private tradingActive;

    function shouldTakeFee(address sender) internal view returns (bool) {
        return !isFeeExempt[sender];
    }

    receive() external payable {}

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual override {
        if (!tradingActive) {
            require(
                isFeeExempt[sender] || isFeeExempt[recipient],
                "Trading is not active."
            );
        }
        if (recipient != pair && recipient != DEAD) {
            require(
                isTxLimitExempt[recipient] ||
                    balanceOf(recipient) + amount <= _maxWalletAmount,
                "Transfer amount exceeds the bag size."
            );
        }
        uint256 taxed = shouldTakeFee(sender) ? getFee(amount) : 0;
        super._transfer(sender, recipient, amount - taxed);
        super._burn(sender, taxed);
    }

    function setLimit(uint256 amountPercent) external onlyOwner {
        _maxWalletAmount = (_totalSupply * amountPercent) / 100;
    }

    function openTrading() external onlyOwner {
        tradingActive = true;
    }

    function decimals() public view virtual override returns (uint8) {
        return 9;
    }

    constructor() ERC20(_name, _symbol) {
        rt = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        pair = IUniswapV2Factory(rt.factory()).createPair(
            rt.WETH(),
            address(this)
        );
        isFeeExempt[owner()] = true;
        isFeeExempt[address(this)] = true;
        isFeeExempt[address(0xdead)] = true;

        isTxLimitExempt[owner()] = true;
        isTxLimitExempt[DEAD] = true;
        _mint(owner(), _totalSupply);
        emit Transfer(address(0), owner(), _totalSupply);
    }

    function getFee(uint256 amount) internal view returns (uint256) {
        uint256 feeAmount = (amount * fee) / 100;
        return feeAmount;
    }
}
