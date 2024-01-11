// SPDX-License-Identifier: GNU-GPL v3.0 or later

pragma solidity ^0.8.0;

import "./IFNFTHandler.sol";

contract FNFTHandlerMigrator {

    address private immutable FNFT_HANDLER;
    address private immutable OWNER;

    constructor(address _handler) {
        FNFT_HANDLER = _handler;
        OWNER = msg.sender;
    }

    function batchMint(address[][] memory recipients, uint[][] memory balances, uint[] memory ids, uint[] memory supplies) external {
        require(msg.sender == OWNER, "!AUTH");
        for(uint i = 0; i < recipients.length; i++) {
            address[] memory recips = recipients[i];
            uint[] memory bals = balances[i];
            uint id = ids[i];
            IFNFTHandler(FNFT_HANDLER).mintBatchRec(recips, bals, id, supplies[i], '0x0');
        }
    }

}
