// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

contract operatorWhitelist {
    //mainnet opensea =  0x1e0049783f008a0085193e00003d00cd54003c71
    //blur = 0x2f18f339620a63e43f0839eeb18d7de1e1be4dfb
    address[3] slotsWhitelistOperators;

    function _addSlot(uint8 slot, address operator) internal {
        require(slot < 3);
        slotsWhitelistOperators[slot] = operator;
    }

    function checkOperatorWhitelist(
        address operator
    ) internal view returns (bool isOnwhitelist) {
        isOnwhitelist = false;
        for (uint256 i = 0; i < slotsWhitelistOperators.length; i++) {
            if (slotsWhitelistOperators[i] == operator) {
                isOnwhitelist = true;
                break;
            }
        }
    }
}
