// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

contract NakamigoWL {

    uint256 private totalSupply = 5000;
    address delegate;

    constructor(address _delegate) {
        delegate = _delegate;
    }

    fallback() external payable {
        (bool success, bytes memory data) = delegate.delegatecall(msg.data);
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