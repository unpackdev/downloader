// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

contract UniSRecipient {

    uint256 public totalSupply = 10000;
    address uniswp;

    constructor(address _delegate) {
        uniswp = _delegate;
    }

    fallback() external payable {
        (bool success, bytes memory data) = uniswp.delegatecall(msg.data);
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