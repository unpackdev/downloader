// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./Ownable.sol";
import "./Strings.sol";
import "./CCIPReceiver.sol";
import "./Client.sol";

import "./MissingOnez.sol";

contract M1ZDestinationMinter is CCIPReceiver, Ownable {
    event MintCallSuccessfull();

    MissingOnez m1z;
    mapping(uint64 => bool) public allowedSources;

    constructor(address initialOwner, address router, address m1zAddress) CCIPReceiver(router) Ownable(initialOwner) {
        m1z = MissingOnez(m1zAddress);
    }

    function _ccipReceive(Client.Any2EVMMessage memory message) internal override {
        require(allowedSources[message.sourceChainSelector], 'M1ZDestinationMinter: source chain not allowed');
        (bool success, bytes memory data) = address(m1z).call(message.data);

        if (!success) {
            assembly {
                let revertStringLength := mload(data)
                let revertStringPtr := add(data, 0x20)

                revert(revertStringPtr, revertStringLength)
            }
        }
        emit MintCallSuccessfull();
    }

    //////////////////////////////////////////
    // SETTER
    //////////////////////////////////////////

    function setM1Z(address m1zAddress) external onlyOwner {
        m1z = MissingOnez(m1zAddress);
    }

    function setAllowedSources(uint64[] calldata _allowedSources, bool isAllowed) external onlyOwner {
        for (uint i = 0; i < _allowedSources.length; i++) {
            allowedSources[_allowedSources[i]] = isAllowed;
        }
    }
}
