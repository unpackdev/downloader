pragma solidity ^0.6.9;

import "./BetTokenHolder.sol";

import "./IERC777Sender.sol";
import "./ERC1820Implementer.sol";

abstract contract BetTokenSender is BetTokenHolder, IERC777Sender, ERC1820Implementer {
    bytes32 constant public TOKENS_SENDER_INTERFACE_HASH = keccak256("ERC777TokensSender");

    constructor () public {
        _registerInterfaceForAddress(TOKENS_SENDER_INTERFACE_HASH, address(this));
    }

    function tokensToSend(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes calldata userData,
        bytes calldata operatorData
    ) external override isRightToken {}

    function send (address to, uint amount) internal {
        token.send(to, amount, "");
    }
}