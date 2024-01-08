// SPDX-License-Identifier: MIT
// @author: https://github.com/SHA-2048

pragma solidity 0.8.0;

import "./IERC20.sol";
import "./ERC20.sol";

/**
 * Contract logic borrowed from sushi's SushiBar
 * open source contract
 *
 * $TOKEN refers to any ERC20 used by the contract
 * as underlying asset
 *
 * The goal here is to share $TOKEN revenues with users
 * staking their $TOKEN in the contract
 *
 * Each stake mints $rsTOKEN shares. These shares
 * gain in value with time as the contract receives
 * more $TOKEN from trading fees.
 *
 * At leave, $rsTOKEN shares will be burned to unlock
 * underlying $TOKEN
 *
 * WARNING: If $rsTOKEN tokens are transferred to the
 * the contract, it is equivalent to a burn and
 * underlying $TOKEN tokens will get distributed
 * to existing $rsTOKEN holders
 */

contract RevenueShare is ERC20 {

    IERC20 public underlying;

    constructor(
        IERC20 _underlying,
        string memory _name,
        string memory _symbol
    ) ERC20(_name, _symbol) {
        underlying = _underlying;
    }

    function enter(uint _underlyingAmount) external {
        _mint(msg.sender, _shares(_underlyingAmount));
        underlying.transferFrom(msg.sender, address(this), _underlyingAmount);
    }

    function leave(uint _shareAmount) external {
        underlying.transfer(msg.sender, _underlyingOf(_shareAmount));
        _burn(msg.sender, _shareAmount);
    }

    function sharePrice() external view returns (uint) {
        uint shares = _totalSupply();
        if (shares == 0) {
            return 1e18;
        }

        return balanceUnderlying() * 1e18 / shares;
    }

    function balanceUnderlying() public view returns (uint) {
        return underlying.balanceOf(address(this));
    }

    function burnLockedShares() external {
        _burn(address(this), _lockedShares());
    }

    function _shares(uint _underlyingAmount) internal view returns (uint) {
        uint totalShares = _totalSupply();
        if (totalShares == 0) {
            return _underlyingAmount;
        }

        uint totalStaked = underlying.balanceOf(address(this));
        return _underlyingAmount * totalShares / totalStaked;
    }

    function _underlyingOf(uint _shareAmount) internal view returns (uint) {
        uint totalShares = _totalSupply();
        if (totalShares == 0) {
            return 0;
        }

        uint totalStaked = underlying.balanceOf(address(this));
        return _shareAmount * totalStaked / totalShares;
    }

    function _totalSupply() internal view returns(uint) {
        return totalSupply() - _lockedShares();
    }

    function _lockedShares() internal view returns(uint) {
        return balanceOf(address(this));
    }
}