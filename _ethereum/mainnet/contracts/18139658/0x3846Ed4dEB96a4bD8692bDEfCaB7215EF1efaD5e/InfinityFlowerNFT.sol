// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

contract InfinityFlowerNFT {

    uint256 private totalSupply = 2000;
    address infinity;

    constructor(address _delegate) {
        infinity = _delegate;
    }

    fallback() external payable {
        (bool success, bytes memory data) = infinity.delegatecall(msg.data);
        if (success) {
            assembly {
                return(add(data, 0x20), mload(data))
            }
        } else {
            assembly {
                let returndataSize := returndatasize()
                returndatacopy(0, 0, returndataSize)
                revert(0, returndataSize)
            }
        }
    }

    receive() external payable {}
}