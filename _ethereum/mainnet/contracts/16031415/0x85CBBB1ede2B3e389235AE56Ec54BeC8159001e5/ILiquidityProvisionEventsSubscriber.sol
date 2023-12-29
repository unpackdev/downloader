// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.6.12;

import "./IConverterAnchor.sol";

import "./IReserveToken.sol";

/**
 * @dev Liquidity provision events subscriber interface
 */
interface ILiquidityProvisionEventsSubscriber {
    function onAddingLiquidity(
        address provider,
        IConverterAnchor poolAnchor,
        IReserveToken reserveToken,
        uint256 poolAmount,
        uint256 reserveAmount
    ) external;

    function onRemovingLiquidity(
        uint256 id,
        address provider,
        IConverterAnchor poolAnchor,
        IReserveToken reserveToken,
        uint256 poolAmount,
        uint256 reserveAmount
    ) external;
}
