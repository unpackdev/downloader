//SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0;

import "./IGatewayHandler.sol";
import "./PartCollection.sol";

contract DavaOfficial is PartCollection {
    constructor(IGatewayHandler gatewayHandler_, address dava_)
        PartCollection(gatewayHandler_, dava_)
    {}

    function name() public pure returns (string memory) {
        return "dava-official";
    }
}
