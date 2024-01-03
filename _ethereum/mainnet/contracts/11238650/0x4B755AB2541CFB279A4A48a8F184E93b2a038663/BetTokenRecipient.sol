pragma solidity ^0.6.9;

import "./BetTokenHolder.sol";
import "./IERC777Recipient.sol";
import "./IERC1820Registry.sol";


abstract contract BetTokenRecipient is BetTokenHolder, IERC777Recipient {
    IERC1820Registry private _erc1820 = IERC1820Registry(0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24);
    bytes32 constant private TOKENS_RECIPIENT_INTERFACE_HASH = keccak256("ERC777TokensRecipient");

    constructor () public {
        _erc1820.setInterfaceImplementer(address(this), TOKENS_RECIPIENT_INTERFACE_HASH, address(this));
    }

    function tokensReceived(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes calldata userData,
        bytes calldata operatorData
    ) external override isRightToken {
        bet(from, amount, userData);
    }

    function bet (address from, uint amount, bytes memory betData) internal virtual {}
}