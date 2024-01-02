// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./ExchangeWrapperCore.sol";

contract ExchangeWrapper is ExchangeWrapperCore {
    function __ExchangeWrapper_init(
        address _exchangeV2,
        address _rarible,
        address _seaport_1_4,
        address _seaport_1_5,
        address _x2y2,
        address _looksrare,
        address _sudoswap,
        address _blur
    ) external initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
        __Pausable_init_unchained();
        __ExchangeWrapper_init_unchained(
            _exchangeV2,
            _rarible,
            _seaport_1_4,
            _seaport_1_5,
            _x2y2,
            _looksrare,
            _sudoswap,
            _blur
        );
    }
}
