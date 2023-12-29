// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "./IRouterSwapResolver.sol";

import "./IArrakisV2Resolver.sol";
import "./IArrakisV2Helper.sol";
import "./IArrakisV2.sol";

import "./IERC20Metadata.sol";
import "./FullMath.sol";

contract RouterSwapResolver is IRouterSwapResolver {
    IArrakisV2Helper public immutable helper;
    IArrakisV2Resolver public immutable resolver;

    constructor(IArrakisV2Helper helper_, IArrakisV2Resolver resolver_) {
        require(
            address(helper_) != address(0) && address(resolver_) != address(0),
            "Z"
        );
        helper = helper_;
        resolver = resolver_;
    }

    // solhint-disable-next-line function-max-lines, code-complexity
    function calculateSwapAmount(
        IArrakisV2 vault,
        uint256 amount0In,
        uint256 amount1In,
        uint256 price18Decimals
    ) external view override returns (bool zeroForOne, uint256 swapAmount) {
        (uint256 gross0, uint256 gross1) = _getUnderlyingOrLiquidity(vault);
        if (gross1 == 0) {
            return (false, amount1In);
        }
        if (gross0 == 0) {
            return (true, amount0In);
        }

        uint256 amount0Left;
        uint256 amount1Left;
        if (amount0In > 0 && amount1In > 0) {
            (uint256 amount0, uint256 amount1, ) = resolver.getMintAmounts(
                vault,
                amount0In,
                amount1In
            );
            amount0Left = amount0In - amount0;
            amount1Left = amount1In - amount1;
        } else {
            amount0Left = amount0In;
            amount1Left = amount1In;
        }

        uint256 factor0 = 10 **
            (18 - IERC20Metadata(address(vault.token0())).decimals());
        uint256 factor1 = 10 **
            (18 - IERC20Metadata(address(vault.token1())).decimals());
        uint256 weightX18 = FullMath.mulDiv(
            gross0 * factor0,
            1 ether,
            gross1 * factor1
        );
        uint256 proportionX18 = FullMath.mulDiv(
            weightX18,
            price18Decimals,
            1 ether
        );
        uint256 factorX18 = FullMath.mulDiv(
            proportionX18,
            1 ether,
            proportionX18 + 1 ether
        );

        uint256 value0To1Left = (amount0Left * factor0 * price18Decimals) /
            1 ether;
        uint256 value1To0Left = amount1Left * factor1;

        if (value0To1Left > value1To0Left) {
            zeroForOne = true;
            swapAmount = FullMath.mulDiv(
                amount0Left,
                1 ether - factorX18,
                1 ether
            );
        } else if (value0To1Left < value1To0Left) {
            swapAmount = FullMath.mulDiv(amount1Left, factorX18, 1 ether);
        }
    }

    // #region view internal functions.

    function _getUnderlyingOrLiquidity(IArrakisV2 vault)
        internal
        view
        returns (uint256 gross0, uint256 gross1)
    {
        (gross0, gross1) = helper.totalUnderlying(vault);
        if (gross0 == 0 && gross1 == 0) {
            gross0 = vault.init0();
            gross1 = vault.init1();
        }
    }

    // #endregion view internal functions.
}
