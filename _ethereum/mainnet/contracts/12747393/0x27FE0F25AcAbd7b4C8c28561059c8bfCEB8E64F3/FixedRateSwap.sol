// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./Math.sol";
import "./ERC20.sol";
import "./SafeERC20.sol";


contract FixedRateSwap is ERC20, Ownable {
    using SafeERC20 for IERC20;

    IERC20 immutable public token0;
    IERC20 immutable public token1;

    uint8 immutable private _decimals;

    uint256 immutable private _feeScale = 1e18;
    uint256 immutable private _minAmountMultiplier = 1e18;
    uint256 immutable private _maxAmountMultiplier = 0.99e18;

    constructor(
        IERC20 _token0,
        IERC20 _token1,
        string memory name,
        string memory symbol,
        uint8 decimals_
    )
        ERC20(name, symbol)
    {
        token0 = _token0;
        token1 = _token1;
        _decimals = decimals_;
    }

    function decimals() public view virtual override returns(uint8) {
        return _decimals;
    }

    function getReturn(IERC20 tokenFrom, IERC20 tokenTo, uint256 inputAmount) public view returns(uint256 outputAmount) {
        uint256 fromBalance = tokenFrom.balanceOf(address(this));
        uint256 toBalance = tokenTo.balanceOf(address(this));
        uint256 averageRatio = 0.5e18 * (fromBalance + fromBalance + inputAmount) / (fromBalance + toBalance);
        uint256 multiplierWeight = _getWeight(averageRatio);
        uint256 amountMultiplier = (_minAmountMultiplier * multiplierWeight + _maxAmountMultiplier * (1e18 - multiplierWeight)) / 1e18;
        outputAmount = inputAmount * amountMultiplier / _feeScale;
    }

    function deposit(uint256 token0Amount, uint256 token1Amount) external returns(uint256 share) {
        share = depositFor(token0Amount, token1Amount, msg.sender);
    }

    function depositFor(uint256 token0Amount, uint256 token1Amount, address to) public onlyOwner returns(uint256 share) {
        uint256 inputAmount = token0Amount + token1Amount;
        require(inputAmount > 0, "Empty deposit is not allowed");

        uint256 _totalSupply = totalSupply();
        share = inputAmount;
        if (_totalSupply > 0) {
            uint256 totalBalance = token0.balanceOf(address(this)) + token1.balanceOf(address(this));
            share = inputAmount * _totalSupply / totalBalance;
        }

        if (token0Amount > 0) {
            token0.safeTransferFrom(msg.sender, address(this), token0Amount);
        }
        if (token1Amount > 0) {
            token1.safeTransferFrom(msg.sender, address(this), token1Amount);
        }
        _mint(to, share);
    }

    function withdraw(uint256 amount) external returns(uint256 token0Share, uint256 token1Share) {
        (token0Share, token1Share) = withdrawFor(amount, msg.sender);
    }

    function withdrawFor(uint256 amount, address to) public returns(uint256 token0Share, uint256 token1Share) {
        require(amount > 0, "Empty withdrawal is not allowed");

        uint256 _totalSupply = totalSupply();
        token0Share = token0.balanceOf(address(this)) * amount / _totalSupply;
        token1Share = token1.balanceOf(address(this)) * amount / _totalSupply;

        _burn(msg.sender, amount);
        if (token0Share > 0) {
            token0.safeTransfer(to, token0Share);
        }
        if (token1Share > 0) {
            token1.safeTransfer(to, token1Share);
        }
    }

    function swap0To1(uint256 inputAmount) external returns(uint256 outputAmount) {
        outputAmount = swap0To1For(inputAmount, msg.sender);
    }

    function swap1To0(uint256 inputAmount) external returns(uint256 outputAmount) {
        outputAmount = swap1To0For(inputAmount, msg.sender);
    }

    function swap0To1For(uint256 inputAmount, address to) public returns(uint256 outputAmount) {
        return _swap(token0, token1, inputAmount, to);
    }

    function swap1To0For(uint256 inputAmount, address to) public returns(uint256 outputAmount) {
        return _swap(token1, token0, inputAmount, to);
    }

    function _swap(IERC20 tokenFrom, IERC20 tokenTo, uint256 inputAmount, address to) private returns(uint256 outputAmount) {
        outputAmount = getReturn(tokenFrom, tokenTo, inputAmount);
        require(outputAmount > 0, "Empty swap is not allowed");
        tokenFrom.safeTransferFrom(msg.sender, address(this), inputAmount);
        tokenTo.safeTransfer(to, outputAmount);
    }

    function _getWeight(uint256 ratio) private pure returns(uint256 weight) {
        int256 r = 0.7626985859023444e18 - int256(ratio) * 1.7621075643977235e18 / 1e18;
        int256 rr = r * r / 1e18;  // r^2
        rr = rr * rr / 1e18;  // r^4
        rr = rr * rr / 1e18;  // r^8
        rr = rr * rr / 1e18;  // r^16
        rr = rr * r / 1e18;  // r^17
        return Math.min(Math.max(0, uint256(rr + 0.99e18)), 1e18);
    }
}
