// SPDX-License-Identifier: MIT
/**
Website: https://www.spongepepe.vip/
TG: https://t.me/spongepepe
Twitter: https://twitter.com/Spongepepe_eth
**/
pragma solidity ^0.8.20;
import "./ERC20.sol";
import "./Ownable.sol";
import "./IERC20.sol";

contract spongePEPE is Ownable, ERC20 {
    bool public limited;
    uint256 public maxHoldingAmount;
    uint256 public minHoldingAmount;
    address public uniswapV2Pair;

    constructor(uint256 _totalSupply) ERC20("spongePEPE", "spongePEPE") {
        _mint(msg.sender, _totalSupply);
    }

    function setRule(bool _limited, address _uniswapV2Pair, uint256 _maxHoldingAmount, uint256 _minHoldingAmount) external onlyOwner {
        limited = _limited;
        uniswapV2Pair = _uniswapV2Pair;
        maxHoldingAmount = _maxHoldingAmount;
        minHoldingAmount = _minHoldingAmount;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) override internal virtual {

        if (uniswapV2Pair == address(0)) {
            require(from == owner() || to == owner(), "trading is not started");
            return;
        }

        if (limited && from == uniswapV2Pair) {
            require(super.balanceOf(to) + amount <= maxHoldingAmount && super.balanceOf(to) + amount >= minHoldingAmount, "Forbid");
        }
    }

    function burn(uint256 value) external {
        _burn(msg.sender, value);
    }
}