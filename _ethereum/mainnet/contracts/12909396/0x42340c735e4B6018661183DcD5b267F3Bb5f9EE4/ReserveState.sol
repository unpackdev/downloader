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

import "./Decimal.sol";
import "./Implementation.sol";

/**
 * @title ReserveTypes
 * @notice Contains all reserve state structs
 */
contract ReserveTypes {

    /**
     * @notice Stores state for a single order
     */
    struct Order {
        /**
         * @notice price (takerAmount per makerAmount) for the order as a Decimal
         */
        Decimal.D256 price;

        /**
         * @notice total available amount of the maker token
         */
        uint256 amount;
    }

    /**
     * @notice Stores state for the entire reserve
     */
    struct State {

        /**
         * @notice Mapping of all registered limit orders
         */
        mapping(address => mapping(address => ReserveTypes.Order)) orders;
    }
}

/**
 * @title ReserveState
 * @notice Reserve state
 */
contract ReserveState {

    /**
     * @notice Entirety of the reserve contract state
     * @dev To upgrade state, append additional state variables at the end of this contract
     */
    ReserveTypes.State internal _state;
}

/**
 * @title ReserveAccessors
 * @notice Reserve state accessor helpers
 */
contract ReserveAccessors is Implementation, ReserveState {
    using SafeMath for uint256;
    using Decimal for Decimal.D256;

    // SWAPPER

    /**
     * @notice Full state of the `makerToken`-`takerToken` order
     * @param makerToken Token that the reserve wishes to sell
     * @param takerToken Token that the reserve wishes to buy
     * @return Specified order
     */
    function order(address makerToken, address takerToken) public view returns (ReserveTypes.Order memory) {
        return _state.orders[makerToken][takerToken];
    }

    /**
     * @notice Sets the `price` and `amount` of the specified `makerToken`-`takerToken` order
     * @dev Internal only
     * @param makerToken Token that the reserve wishes to sell
     * @param takerToken Token that the reserve wishes to buy
     * @param price Price as a ratio of takerAmount:makerAmount times 10^18
     * @param amount Amount to decrement in ESD
     */
    function _updateOrder(address makerToken, address takerToken, uint256 price, uint256 amount) internal {
        _state.orders[makerToken][takerToken] = ReserveTypes.Order({price: Decimal.D256({value: price}), amount: amount});
    }

    /**
     * @notice Decrements the available amount of the specified `makerToken`-`takerToken` order
     * @dev Internal only
            Reverts when insufficient amount with reason `reason`
     * @param makerToken Token that the reserve wishes to sell
     * @param takerToken Token that the reserve wishes to buy
     * @param amount Amount to decrement in ESD
     * @param reason revert reason
     */
    function _decrementOrderAmount(address makerToken, address takerToken, uint256 amount, string memory reason) internal {
        _state.orders[makerToken][takerToken].amount = _state.orders[makerToken][takerToken].amount.sub(amount, reason);
    }
}
