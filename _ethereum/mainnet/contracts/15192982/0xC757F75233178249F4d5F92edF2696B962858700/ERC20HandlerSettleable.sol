// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.0;

import "./ERC20Handler.sol";
import "./Settleable.sol";

contract ERC20HandlerSettleable is ERC20Handler, Settleable {
    constructor(address bridgeAddress)
        ERC20Handler(bridgeAddress)
        Settleable(bridgeAddress)
    {}

    function _settle(address destResourceAddress, KeyValuePair[] memory entries)
        internal
        virtual
        override
    {
        require(
            _contractWhitelist[destResourceAddress],
            "not an allowed token address"
        );

        if (_burnList[destResourceAddress]) {
            for (uint256 i = 0; i < entries.length; i++) {
                address account = abi.decode(entries[i].key, (address));
                uint256 amount = abi.decode(entries[i].value, (uint256));
                mintERC20(destResourceAddress, account, amount);
            }
        } else {
            for (uint256 i = 0; i < entries.length; i++) {
                address account = abi.decode(entries[i].key, (address));
                uint256 amount = abi.decode(entries[i].value, (uint256));
                releaseERC20(destResourceAddress, account, amount);
            }
        }
    }
}
