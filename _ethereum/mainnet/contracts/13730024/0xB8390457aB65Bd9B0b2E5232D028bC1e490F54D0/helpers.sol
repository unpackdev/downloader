pragma solidity ^0.8.6;
pragma experimental ABIEncoderV2;

import "./math.sol";
import "./variables.sol";
import "./SafeERC20.sol";
import "./IERC20.sol";

abstract contract Helpers is DSMath, Variables {
    function _checkLiquidity (
        Position memory position,
        address liquidityContract,
        bool isSupply,
        bool isTargetToken
    ) internal view returns (PositionData memory p) {
        p.isOk = true;
        if (isSupply) {
            uint256 supplyLen = position.supply.length;
            p.supply = new LiquidityData[](supplyLen);
            for (uint256 i = 0; i < supplyLen; i++) {
                uint256 amount = position.supply[i].amount;
                address token = isTargetToken ? position.supply[i].targetToken : position.supply[i].sourceToken;
                p.supply[i].token = token;
                if (token == nativeToken) {
                    p.supply[i].liquidityAvailable = liquidityContract.balance;
                } else {
                    p.supply[i].liquidityAvailable = IERC20(token).balanceOf(liquidityContract);
                }
                if (amount > p.supply[i].liquidityAvailable) {
                    p.isOk = false;
                    p.supply[i].liquidityShort = sub(amount, p.supply[i].liquidityAvailable);
                }
            }
        }


        if (!isSupply) {
            uint256 withdrawLen = position.withdraw.length;
            p.withdraw = new LiquidityData[](withdrawLen);
            for (uint256 i = 0; i < withdrawLen; i++) {
                uint256 amount = position.withdraw[i].amount;
                address token = isTargetToken ? position.withdraw[i].targetToken : position.withdraw[i].sourceToken;
                p.withdraw[i].token = token;
                if (token == nativeToken) {
                    p.withdraw[i].liquidityAvailable = liquidityContract.balance;
                } else {
                    p.withdraw[i].liquidityAvailable = IERC20(token).balanceOf(liquidityContract);
                }
                if (amount > p.withdraw[i].liquidityAvailable) {
                    p.isOk = false;
                    p.withdraw[i].liquidityShort = sub(amount, p.withdraw[i].liquidityAvailable);
                }
            }
        }
    }

    function _getLiquidity(
        address[] memory tokens,
        address liquidityContract
    ) internal view returns (LiquidityData[] memory l) {
        uint256 len = tokens.length;
        l = new LiquidityData[](len);
        for (uint256 i = 0; i < len; i++) {
            address token = tokens[i];
            l[i].token = token;
            if (token == nativeToken) {
                l[i].liquidityAvailable = liquidityContract.balance;
            } else {
                l[i].liquidityAvailable = IERC20(token).balanceOf(liquidityContract);
            }
        }
    }



    struct PositionData {
        bool isOk;
        LiquidityData[] supply;
        LiquidityData[] withdraw;
    }

    struct LiquidityData {
        address token;
        uint256 liquidityAvailable;
        uint256 liquidityShort;
    }
}