// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "./WmbApp.sol";

contract PingPong is WmbApp {
    uint256 public pingCount;
    uint256 public pongCount;

    constructor(address admin, address _wmbGateway) WmbApp() {
        initialize(admin, _wmbGateway);
    }

    // Transfer in enough native coin for fee. 
    receive() external payable {}

    function _wmbReceive(
        bytes calldata data,
        bytes32 /*messageId*/,
        uint256 fromChainId,
        address from
    ) internal override {
        if (data[0] == 0x01) {
            pingCount++;
            uint fee = estimateFee(fromChainId, 200_000);
            _dispatchMessage(fromChainId, from, abi.encodePacked(bytes1(0x02)), fee);
        } else if (data[0] == 0x02) {
            pongCount++;
        }
    }

    // send ping message 
    function ping(uint256 toChainId, address to) public {
        uint fee = estimateFee(toChainId, 200_000);
        _dispatchMessage(toChainId, to, abi.encodePacked(bytes1(0x01)), fee);
    }
}
