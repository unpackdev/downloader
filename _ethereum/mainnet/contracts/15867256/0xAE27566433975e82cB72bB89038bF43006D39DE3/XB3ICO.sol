// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

import "./Ownable.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./Pausable.sol";

interface IERC20withDecimals is IERC20 {
    function decimals() external pure returns(uint8);
}

contract XB3ICO is Pausable, Ownable {

    using SafeERC20 for IERC20;
    using SafeERC20 for IERC20withDecimals;

    IERC20withDecimals public paymentToken; // Token accepted as payment
    IERC20 public token;    // Token to purchase
    uint256 public currentSupply;   // Total amount of tokens bought on ICO
    uint256 public immutable initialPrice;    // Initial price of token. Denoted by p0 in formula
    uint256 public immutable limitPrice;    // Limit price of token. Denoted by A in formula
    uint256 public immutable rateCoeff; // The rate of price rising. Denoted by B in formula
    uint256 public immutable point; // An absolute value of bias for price graph. Denoted by b in formula
    uint256 public immutable maxSupply; // Max total supply for token
    uint256 immutable decimals; // Decimals points of payment token 

    uint256 constant MULTIPLIER = 1e18;

    event Bought(address user, uint256 cost, uint256 amount);
    event Withdrawn(address to, uint256 amount);
    constructor (
        address _paymentToken,
        address _token,
        uint256 _initialPrice,
        uint256 _limitPrice,
        uint256 _rateCoeff,
        uint256 _point,
        uint256 _maxSupply
    ) {
        paymentToken = IERC20withDecimals(_paymentToken);    
        token = IERC20(_token);
        initialPrice = _initialPrice;
        limitPrice = _limitPrice;
        rateCoeff = _rateCoeff;
        point = _point;
        maxSupply = _maxSupply;
        decimals = IERC20withDecimals(_paymentToken).decimals();
        _pause();
    }

    function pause() public whenNotPaused onlyOwner {
        _pause();
    }

    function unpause() public whenPaused onlyOwner {
        _unpause();
    }

    function buy(uint256 _amountIn) external whenNotPaused {
        require(currentSupply < maxSupply, "Sold out");
        uint256 dec = decimals;
        _amountIn = _amountIn * 10 ** (18 - dec);
        (uint256 cost, uint256 calculated) = _calculateAmountOut(_amountIn);
        cost = cost / (10 ** (18 - dec));
        currentSupply += calculated;
        paymentToken.safeTransferFrom(_msgSender(), address(this), cost);
        token.transfer(_msgSender(), calculated);
        emit Bought(_msgSender(), cost, calculated);
    }

    function withdraw(address _to, uint256 _amount) public onlyOwner {
        paymentToken.safeTransfer(_to, _amount);
        emit Withdrawn(_to, _amount);
    }

    function withdraw(address _to) external onlyOwner {
        uint256 balance = paymentToken.balanceOf(address(this));
        withdraw(_to, balance);
    }

    function _calculateAmountOut(uint256 _amountIn) public view returns(uint256 cost, uint256 amountOut) {
        require(_amountIn < uint256(type(int256).max), "amountIn is too large");
        uint256 base = MULTIPLIER;
        uint256 current = currentSupply;
        uint256 max = maxSupply;
        uint256 biasedSupply = current + point;
        uint256 limit = limitPrice;
        uint256 rate = rateCoeff;
        int256 term = int256(_amountIn) + int256(rate * base / biasedSupply) - int256(limit * biasedSupply / base);
        amountOut = uint256( (term + int256(sqrt(term ** 2 + int256(4 * limit * biasedSupply * _amountIn / base) ))) * int256(base) / int256(2 * limit) );
        cost = _amountIn;
        if(amountOut > max - current) {
            amountOut = max - current;
            cost = limit * amountOut / base + rate * base / (biasedSupply + amountOut) - rate * base / biasedSupply;
        }
    }

    function sqrt(int256 x) public view returns (int256 y) {
        int256 z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }
}

