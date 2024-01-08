// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./AccessControl.sol";
import "./ECDSA.sol";
import "./IExchangeProvider.sol";

contract ExchangeProvider is IExchangeProvider, AccessControl {
    address public override exchange;

    function setExchange(address _exchange) external {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "Factory: Only admin allowed"
        );

        exchange = _exchange;
    }
}