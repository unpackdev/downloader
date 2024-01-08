// Copyright (C) 2021 Exponent

// This file is part of Exponent.

// Exponent is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// Exponent is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with Exponent.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity 0.8.0;

// @title core application logic and API for trade submissions
abstract contract XPNSettlement {
    event SubmitTradeOrders(address indexed, bytes[], address[]);
    event Lend(address indexed, bytes, address);
    event Redeem(address indexed, bytes, address);

    // actions taken on liquidity or lending pool
    enum Pool {
        LEND,
        REDEEM
    }

    // @notice submit multiple trade orders
    // @param _trades array of ABI encoded trades to submit
    // @param _venues array of trading venues address
    // @dev each order based on corresponding index of the input
    function _submitTradeOrders(
        bytes[] calldata _trades,
        address[] memory _venues
    ) internal virtual returns (bool) {
        require(
            _venues.length == _trades.length,
            "TradeSettlement: trade submissions input length not equal"
        );
        for (uint8 i = 0; i < _trades.length; i++) {
            require(
                _venueIsWhitelisted(_venues[i]),
                "XPNSettlement: venue is not whitelisted"
            );
            bool success = _submitTrade(_trades[i], _venues[i]);
            require(success, "XPNSettlement: a trade did not execute");
        }
        emit SubmitTradeOrders(msg.sender, _trades, _venues);
        return true;
    }

    // @notice submit multiple pool orders
    // @param _orders array of ABI encoded trades to submit
    // @param _txTypes array of order type, either redeem or lend
    // @param _venues array of trading venues address
    // @dev each order based on corresponding index of the input
    function _submitPoolOrders(
        bytes[] calldata _orders,
        Pool[] calldata _txTypes,
        address[] memory _venues
    ) internal virtual returns (bool) {
        require(
            _orders.length == _txTypes.length &&
                _orders.length == _venues.length,
            "TradeSettlement: pool submissions input length not equal"
        );

        for (uint8 i = 0; i < _orders.length; i++) {
            require(
                _venueIsWhitelisted(_venues[i]),
                "XPNSettlement: venue is not whitelisted"
            );
            bool success = _txTypes[i] == Pool.LEND
                ? _lend(_orders[i], _venues[i])
                : _redeem(_orders[i], _venues[i]);
            require(success, "XPNSettlement: a trade did not execute");
        }
        return true;
    }

    // @notice submit lending order to lending protocol
    // @param _order ABI encoded lending arguements to submit
    // @param _venue trading venue address
    function _lend(bytes calldata _order, address _venue)
        private
        returns (bool)
    {
        bool success = _submitLending(_order, _venue);
        emit Lend(msg.sender, _order, _venue);
        return success;
    }

    // @notice submit redemption order from lending protocol
    // @param _order ABI encoded redemption arguements to submit
    // @param _venue trading venue address
    function _redeem(bytes calldata _order, address _venue)
        private
        returns (bool)
    {
        bool success = _submitRedemption(_order, _venue);
        emit Redeem(msg.sender, _order, _venue);
        return success;
    }

    function _submitTrade(bytes calldata _trade, address _venue)
        internal
        virtual
        returns (bool)
    {}

    function _submitLending(bytes calldata _order, address _venue)
        internal
        virtual
        returns (bool)
    {}

    function _submitRedemption(bytes calldata _order, address _venue)
        internal
        virtual
        returns (bool)
    {}

    function _venueIsWhitelisted(address _venue)
        internal
        view
        virtual
        returns (bool)
    {}
}
