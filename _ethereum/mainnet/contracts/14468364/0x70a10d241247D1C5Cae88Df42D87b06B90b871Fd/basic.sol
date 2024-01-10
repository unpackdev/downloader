// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.3;

import "./IERC20.sol";

import "./math.sol";
import "./TokenInterface.sol";

abstract contract Basic is DSMath {
    address internal constant ethAddr =
        0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    function convert18ToDec(uint256 _dec, uint256 _amt)
        internal
        pure
        returns (uint256 amt)
    {
        amt = (_amt / 10**(18 - _dec));
    }

    function convertTo18(uint256 _dec, uint256 _amt)
        internal
        pure
        returns (uint256 amt)
    {
        amt = mul(_amt, 10**(18 - _dec));
    }

    function getTokenBal(TokenInterface token) internal view returns (uint256 _amt) {
        _amt = address(token) == ethAddr
            ? address(this).balance
            : token.balanceOf(address(this));
    }

    function getTokensDec(TokenInterface buyAddr, TokenInterface sellAddr)
        internal
        view
        returns (uint256 buyDec, uint256 sellDec)
    {
        buyDec = address(buyAddr) == ethAddr ? 18 : buyAddr.decimals();
        sellDec = address(sellAddr) == ethAddr ? 18 : sellAddr.decimals();
    }

    function approve(
        TokenInterface token,
        address spender,
        uint256 amount
    ) internal {
        try token.approve(spender, amount) {} catch {
            token.approve(spender, 0);
            token.approve(spender, amount);
        }
    }
}
