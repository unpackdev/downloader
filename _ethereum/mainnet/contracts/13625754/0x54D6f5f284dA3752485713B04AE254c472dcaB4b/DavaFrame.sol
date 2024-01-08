//SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0;

import "./IGatewayHandler.sol";
import "./FrameCollection.sol";

contract DavaFrame is FrameCollection {
    constructor(IGatewayHandler gatewayHandler_)
        FrameCollection(gatewayHandler_)
    {}

    function name() public pure returns (string memory) {
        return "dava-frame";
    }
}
