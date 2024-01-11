// SPDX-License-Identifier: MIT
pragma solidity >=0.5.17 <0.9.0;

import "./Base64.sol";

contract Hook {

    constructor() {}

    // see https://github.com/unlock-protocol/unlock/blob/master/smart-contracts/contracts/interfaces/hooks/IHook.sol
    function tokenURI(
        address, // lockAddress,
        address, // operator,
        address, // owner,
        uint256, // keyId,
        uint256 expirationTimestamp 
    ) external view returns (string memory) {
        // Defaults to active
        string memory image = "ipfs://QmSeVMWi79C4UKgxrknymVW47yYLtqazChGne18gPH8Hud/active.svg";
        if (expirationTimestamp <= block.timestamp) {
          // Use the expired one
          image = "ipfs://QmSeVMWi79C4UKgxrknymVW47yYLtqazChGne18gPH8Hud/expired.svg";
        }

        // create the json that includes the image
        string memory json = string(
            abi.encodePacked('{ "image": "', image, '", "attributes": [ {"trait_type": "BREAD", "value": "CROISSANT"}, {"trait_type": "PASTRY", "value": "30-DAY"}], "description": "A Pastry", "external_url":"https://pastry.xyz/", "name": "Pastry"}')
        );

        // render the base64 encoded json metadata
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(bytes(abi.encodePacked(json)))
                )
            );
    }
}
