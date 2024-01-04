pragma solidity 0.6.11;

// SPDX-License-Identifier: MIT

import "./ERC20.sol";
import "./IDetailedERC20.sol";

contract WrappedXBTC is ERC20 {
    // A non-rebasing ERC-20 token to wrap xBTC. A wxBTC token always represents the same % of the
    //  total token supply of xBTC, no matter how much xBTC rebases or debases. Due to the way the
    //  math works out, minor rounding errors among the least significant digits are unavoidable.
    //
    // wxBTC is a vanilla ERC-20 token in every way, with the exception of exchanging to/from xBTC.

    using SafeMath for uint256;

    IDetailedERC20 private _wrapped;
    uint256 private _maximumSupply;

    event Deposit(address indexed depositer, uint256 depositAmount, uint256 mintAmount);
    event Withdrawal(address indexed withdrawer, uint256 burnAmount, uint256 withdrawalAmount);

    constructor(IDetailedERC20 wrapContract, uint256 maximumSupply) ERC20(
            // string concatenation
            string(abi.encodePacked('Wrapped ', wrapContract.name())), 
            string(abi.encodePacked('w', wrapContract.symbol()))
    ) public {
        _wrapped = wrapContract;
        _maximumSupply = maximumSupply;
    }

    function wrapped() external view returns (IDetailedERC20) {
        return _wrapped;
    }

    function rawToWrapAmount(uint256 rawAmount) public view returns (uint256) {
        // 100% of total supply of raw token => _maximumSupply wrapped token
        uint256 decimalFactor = 10**uint256(decimals());
        uint256 dividend = rawAmount.mul(_maximumSupply).mul(decimalFactor);
        return dividend.div(_wrapped.totalSupply());
    }

    function wrapToRawAmount(uint256 wrapAmount) public view returns (uint256) {
        // raw token amount = share of contract's controlled raw token proportional to total 
        //  wrap token ownership
        uint256 dividend = wrapAmount.mul(_wrapped.balanceOf(address(this)));
        return dividend.div(totalSupply());
    }

    function deposit(uint256 inAmount) external {
        if (inAmount <= 0) {
            return;
        }

        // transfer the requested amount
        uint256 preBalance = _wrapped.balanceOf(address(this));
        bool transferOk = _wrapped.transferFrom(msg.sender, address(this), inAmount);
        require(transferOk, 'transfer has to be successful');
        uint256 received = _wrapped.balanceOf(address(this)).sub(preBalance);
        require(received >= inAmount, 'must receive at least requested amount');

        // calculate how much to mint
        uint256 mintAmount = rawToWrapAmount(received);

        // mint the wrapped tokens to the user
        _mint(msg.sender, mintAmount);
        emit Deposit(msg.sender, inAmount, mintAmount);
    }

    function withdraw(uint256 burnAmount) external {
        if (burnAmount <= 0) {
            return;
        }

        // calculate how much to withdraw
        uint256 outAmount = wrapToRawAmount(burnAmount);

        // burn the requested amount. this also checks the balance.
        _burn(msg.sender, burnAmount);
        emit Withdrawal(msg.sender, burnAmount, outAmount);

        // send the raw tokens to the user
        bool transferOk = _wrapped.transfer(msg.sender, outAmount);
        require(transferOk, 'transfer has to be successful');
    }
}