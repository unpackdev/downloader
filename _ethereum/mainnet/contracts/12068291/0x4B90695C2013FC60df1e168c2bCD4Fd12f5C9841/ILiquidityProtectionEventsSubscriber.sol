// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.6.12;

import "./IERC20.sol";

import "./IConverterAnchor.sol";

/**
 * @dev Liquidity protection events subscriber interface
 */
interface ILiquidityProtectionEventsSubscriber {
    function onAddingLiquidity(
        address provider,
        IConverterAnchor poolAnchor,
        IERC20 reserveToken,
        uint256 poolAmount,
        uint256 reserveAmount
    ) external;

    function onRemovingLiquidity(
        uint256 id,
        address provider,
        IConverterAnchor poolAnchor,
        IERC20 reserveToken,
        uint256 poolAmount,
        uint256 reserveAmount
    ) external;
}
