/*
    Copyright 2021 Empty Set Squad <emptysetsquad@protonmail.com>

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

pragma solidity 0.5.17;
pragma experimental ABIEncoderV2;

import "./ReserveComptroller.sol";

/**
 * @title ReserveSwapper
 * @notice Logic for managing outstanding reserve limit orders.
 *         Since the reserve is autonomous, it cannot use traditional DEXs without being front-run. The `ReserveSwapper`
 *         allows governance to place outstanding limit orders selling reserve assets in exchange for assets the reserve
 *         wishes to purchase. This is the main mechanism by which the reserve may diversify itself, or buy back ESDS
 *         using generated rewards.
 */
contract ReserveSwapper is ReserveComptroller {
    using SafeMath for uint256;
    using Decimal for Decimal.D256;
    using SafeERC20 for IERC20;

    /**
     * @notice Emitted when `amount` of the `makerToken`-`takerToken` order is registered with price `price`
     */
    event OrderRegistered(address indexed makerToken, address indexed takerToken, uint256 price, uint256 amount);

    /**
     * @notice Emitted when the reserve pays `takerAmount` of `takerToken` in exchange for `makerAmount` of `makerToken`
     */
    event Swap(address indexed makerToken, address indexed takerToken, uint256 takerAmount, uint256 makerAmount);

    /**
     * @notice Sets the `price` and `amount` of the specified `makerToken`-`takerToken` order
     * @dev Owner only - governance hook
     * @param makerToken Token that the reserve wishes to sell
     * @param takerToken Token that the reserve wishes to buy
     * @param price Price as a ratio of takerAmount:makerAmount times 10^18
     * @param amount Amount of the makerToken that reserve wishes to sell - uint256(-1) indicates all reserve funds
     */
    function registerOrder(address makerToken, address takerToken, uint256 price, uint256 amount) external onlyOwner {
        _updateOrder(makerToken, takerToken, price, amount);

        emit OrderRegistered(makerToken, takerToken, price, amount);
    }

    /**
     * @notice Purchases `makerToken` from the reserve in exchange for `takerAmount` of `takerToken`
     * @dev Non-reentrant
     *      Uses the state-defined price for the `makerToken`-`takerToken` order
     *      Maker and taker tokens must be different
     *      Cannot swap ESD
     * @param makerToken Token that the caller wishes to buy
     * @param takerToken Token that the caller wishes to sell
     * @param takerAmount Amount of takerToken to sell
     */
    function swap(address makerToken, address takerToken, uint256 takerAmount) external nonReentrant {
        address dollar = registry().dollar();
        require(makerToken != dollar, "ReserveSwapper: unsupported token");
        require(takerToken != dollar, "ReserveSwapper: unsupported token");
        require(makerToken != takerToken, "ReserveSwapper: tokens equal");

        ReserveTypes.Order memory order = order(makerToken, takerToken);
        uint256 makerAmount = Decimal.from(takerAmount).div(order.price, "ReserveSwapper: no order").asUint256();

        if (order.amount != uint256(-1))
            _decrementOrderAmount(makerToken, takerToken, makerAmount, "ReserveSwapper: insufficient amount");

        _transferFrom(takerToken, msg.sender, address(this), takerAmount);
        _transfer(makerToken, msg.sender, makerAmount);

        emit Swap(makerToken, takerToken, takerAmount, makerAmount);
    }
}
