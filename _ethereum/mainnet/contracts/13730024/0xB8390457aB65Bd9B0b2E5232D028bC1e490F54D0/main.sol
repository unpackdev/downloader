// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./helpers.sol";

contract InteropBalanceResolver is Helpers {
     function checkLiquidity (
        Position memory position,
        address liquidityContract,
        bool isSupply,
        bool isTargetToken
    ) public view returns (PositionData memory p) {
        p = _checkLiquidity(position, liquidityContract, isSupply, isTargetToken);
    }

    function getLiquidity(
        address[] memory tokens,
        address liquidityContract
    ) public view returns (LiquidityData[] memory l) {
        return _getLiquidity(tokens, liquidityContract);
    }

    constructor (
        address _wnativeToken
    ) public {
        wnativeToken = _wnativeToken;
    }
}