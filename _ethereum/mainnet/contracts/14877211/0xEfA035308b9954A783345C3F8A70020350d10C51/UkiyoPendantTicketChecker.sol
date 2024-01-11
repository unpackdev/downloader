// "½▓▓▓▓æM        $▓▓|                                        7G▒▀▓█▓╗▄
//   ████▌M        ▐██│ `▓██▒∩   █▓░"   ▐▀│"  ▀██▓|   ▓▓Γ  ▄███▀╚*   ╙████▄
//   ║███b∩        ▐██∩  ▐██b  ▄█Ñ╙    S▓█▓Ω∞  ╙███y╓█╣╙ ╓████ƒ        ▀███▌,
//   ║███b∩        (██∩  ▐██b╔█▒Q       █▐▌M     ██▓V¢   ████⌠          ████M
//   ║▒▒▒b⌐        ▐▒▒∩  ▐▒▒b╚∩ ▓▒▓\    ▒j▒M     ▐█▒Ñ   (▒▒▒▒│          ║▒▒█▒M
//   ║▒▒▒bM        ▐▒▓∩  ╞▒▒bM   ▓▒▒\   ▒j▒M     ▐▒▒Ñ    ▒▒▒▒│          ▓▒▒▒½∩
//   ╘▒▒▒▒|        ▒▒Ñ∩  ╚▒▒░M    ╙▒▒∞⌐ ╙j░∩     ╘▒▒½¡   ╙▒▒▒NC        ╒▒▒▒▒╡
//    ╙║║║#▄     ,║║╜╛   «▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄,, ╙▒║║░▄     ,#║║║╠∩
//     └╙╚║║╜/##║║╠Ñ╙     '╙╚╙╚╠Ñ╙║║║╠║║║║║║╜╜╚║╜Ñ╚╙"""     ╙╙╚║║░#╠║║╚╠░∩
//         "(╚╚ⁿ"└                 "└  ╚╜Ñ∞╙                    """"""
//                                     └╛
//
//                               "Papers Please"

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;
import "./draft-EIP712.sol";

contract UkiyoPendantTicketChecker is EIP712 {
    string private constant _SIGNING_NAME = "UkiyoPendant";
    string private constant _SIGNATURE_VERSION = "1";
    address private _signerAddress;

    enum TicketType {
        WHITELIST,
        PUBLIC
    }

    // Typed data reference, doesn't look good but saves gas ;)
    // struct Ticket {
    //     address addr;
    //     TicketType ticketType;
    // }

    constructor(address signerAddress_)
        EIP712(_SIGNING_NAME, _SIGNATURE_VERSION)
    {
        _setSigner(signerAddress_);
    }

    modifier validTicket(TicketType ticketType, bytes memory signature) {
        require(
            _signerAddress == _recoverAddress(ticketType, signature),
            "Invalid ticket"
        );
        _;
    }

    function _setSigner(address signerAddress) internal {
        _signerAddress = signerAddress;
    }

    function _recoverAddress(TicketType ticketType, bytes memory signature)
        private
        view
        returns (address)
    {
        bytes32 digest = _hashTypedDataV4(
            keccak256(
                abi.encode(
                    keccak256("Ticket(address addr,uint8 ticketType)"),
                    msg.sender,
                    // Enums are still encoded as uint8 internally
                    ticketType
                )
            )
        );
        return ECDSA.recover(digest, signature);
    }
}
