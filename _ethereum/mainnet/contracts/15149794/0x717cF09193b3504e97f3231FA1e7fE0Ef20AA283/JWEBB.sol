//SPDX-License-Identifier: MIT
/*
 .              +   .                .   . .     .  .
                   .                    .       .     *
  .       *                        . . . .  .   .  + .
            "You Are Here"            .   .  +  . . .
.                 |             .  .   .    .    . .
                  |           .     .     . +.    +  .
                 \|/            .       .   . .
        . .       V          .    * . . .  .  +   .
  .                      .     . + .  . .     .      .
           .      .    .     . .   . . .        ! /
      *             .    . .  +    .  .       - O -
          .     .    .  +   . .  *  .       . / |
       .-.      _______                .  '  *   .  . '
      {}``; |==|_______D                 .  * * -+-  
      / ('        /|\                .    * .    '  *
  (  /  |        / | \                   * .  ' .  . 
   \(_)_]]      /  |  \               *   *  .   .
                                        '   *              
    
    𝗧𝗼 𝗶𝗻𝗳𝗶𝗻𝗶𝘁𝘆 𝗮𝗻𝗱 𝗯𝗲𝘆𝗼𝗻𝗱                                                                                             
*/

pragma solidity ^0.8.5;

import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router02.sol";

import "./ERC20.sol";
import "./IUniswapV2Pair.sol";
import "./Ownable.sol";

contract JWEBB is ERC20, Ownable {
    constructor() ERC20(_name, _symbol) {
        router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        pair = IUniswapV2Factory(router.factory()).createPair(
            router.WETH(),
            address(this)
        );
        isFeeExempt[owner()] = true;
        isTxLimitExempt[owner()] = true;
        isTxLimitExempt[DEAD] = true;
        _mint(owner(), _totalSupply);
        emit Transfer(address(0), owner(), _totalSupply);
    }

    string constant _name = "JWEBB";
    string constant _symbol = "JWEBB";
    uint256 _totalSupply = 555000000 * (10**decimals());
    uint256 public _maxWalletAmount = (_totalSupply * 2) / 100;
    mapping(address => bool) isFeeExempt;
    address DEAD = 0x000000000000000000000000000000000000dEaD;
    uint256 totalFee = 3;
    mapping(address => bool) isTxLimitExempt;
    IUniswapV2Router02 public router;
    address public pair;

    receive() external payable {}

    function decimals() public view virtual override returns (uint8) {
        return 9;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual override {
        if (recipient != pair && recipient != DEAD) {
            require(
                isTxLimitExempt[recipient] ||
                    balanceOf(recipient) + amount <= _maxWalletAmount,
                "Transfer amount exceeds the bag size."
            );
        }
        uint256 taxed = shouldTakeFee(sender) ? getFeeAmounts(amount) : 0;
        super._transfer(sender, recipient, amount - taxed);
        super._burn(sender, taxed);
    }

    function setLimit(uint256 amountPercent) external onlyOwner {
        _maxWalletAmount = (_totalSupply * amountPercent) / 100;
    }

    function getFeeAmounts(uint256 amount) internal view returns (uint256) {
        uint256 feeAmount = (amount * totalFee) / 100;
        return feeAmount;
    }

    function shouldTakeFee(address sender) internal view returns (bool) {
        return !isFeeExempt[sender];
    }
}
