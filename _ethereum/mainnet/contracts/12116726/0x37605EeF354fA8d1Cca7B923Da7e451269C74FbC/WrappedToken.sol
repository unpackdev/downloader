    // SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "./ERC20.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./IWrappedToken.sol";

contract WrappedToken is IWrappedToken, ERC20, Ownable {
    using SafeMath for uint256;

    IERC20 private _underlying;
    uint256 private _totalWrapped;

    constructor(address underlying)
        public
        ERC20("Wrapped Lotto Token", "wLOTTO")
    {
        _underlying = IERC20(underlying);
    }

    /**
     * @dev Wrap underlying tokens
     * @param value The amount of token to wrap in this contract
     */
    function wrap(uint256 value) external override {
        require(value > 0, "WrappedToken: Amount of tokens cannot be equal 0");
        _underlying.transferFrom(msg.sender, address(this), value);
        _mint(msg.sender, value);
        _totalWrapped = _totalWrapped.add(value);
        emit Wrap(msg.sender, value);
    }

    /**
     * @dev Unwrap the underlying token
     * @param value The amount of tokens to unwrap
     */
    function unwrap(uint256 value) external override {
        require(value > 0, "WrappedToken: Amount of tokens cannot be equal 0");
        require(
            _underlying.balanceOf(address(this)) >= value,
            "WrappedToken: Unavailable amount to unwrap"
        );
        _burn(msg.sender, value);
        _underlying.transfer(msg.sender, value);
        _totalWrapped = _totalWrapped.sub(value);
        emit Unwrap(msg.sender, value);
    }

    /**
     * @dev Replenish the contract balance with additional tokens in the underlying asset
     * @param value The amount of tokens to replenish
     */
    function replenish(uint256 value) external override onlyOwner {
        require(value > 0, "WrappedToken: Amount of tokens cannot be equal 0");
        _underlying.transferFrom(msg.sender, address(this), value);
    }

    /**
     * @dev Withdraw extra funds by owner, in case when contract win the lottery
     */
    function withdrawExtraFunds() external override onlyOwner {
        require(
            _underlying.balanceOf(address(this)) > _totalWrapped,
            "WrappedToken: There is nothing to withdraw"
        );
        uint256 extraFunds =
            _underlying.balanceOf(address(this)).sub(_totalWrapped);
        _underlying.transfer(msg.sender, extraFunds);
        emit Withdraw(extraFunds);
    }

    /**
     * @dev Show address of underlying token
     * @return Address of underlying token
     */
    function getUnderlyingToken() external view override returns (IERC20) {
        return _underlying;
    }

    /**
     * @dev Show total wrapped balance
     * @return amount of wrapped tokens balance
     */
    function getTotalWrapped() external view override returns (uint256) {
        return _totalWrapped;
    }
}
