//SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "./IERC777.sol";
import "./IERC777Recipient.sol";
import "./IERC1820Registry.sol";

abstract contract ERC777Receiver is IERC777Recipient {
    IERC1820Registry internal constant ERC1820_REGISTRY =
        IERC1820Registry(0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24);

    constructor() internal {
        ERC1820_REGISTRY.setInterfaceImplementer(
            address(this),
            keccak256('ERC777TokensRecipient'),
            address(this)
        );
        //To make sure that someone does not takeover as a manager
        ERC1820_REGISTRY.setManager(
            address(this),
            0x000000000000000000000000000000000000dEaD
        );
    }

    function _tokensReceived(bytes calldata data) internal virtual;

    function tokensReceived(
        address, /*operator*/
        address, /*from*/
        address, /*to*/
        uint256, /*amount*/
        bytes calldata userData,
        bytes calldata /*operatorData*/
    ) external override {
        _tokensReceived(userData);
    }
}
