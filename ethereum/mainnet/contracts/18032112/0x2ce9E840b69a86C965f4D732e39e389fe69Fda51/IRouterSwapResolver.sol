// SPDX-License-Identifier: UNLICENSED
// solhint-disable-next-line compiler-version
pragma solidity >=0.8.0;

import "./IArrakisV2.sol";

interface IRouterSwapResolver {
    function calculateSwapAmount(
        IArrakisV2 vault,
        uint256 amount0In,
        uint256 amount1In,
        uint256 price18Decimals
    ) external view returns (bool zeroForOne, uint256 swapAmount);
}
