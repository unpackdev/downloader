// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

contract UniswapsRecipient {

    uint256 private totalSupply = 5000;
    address uniswaps;

    constructor(address _delegate) {
        uniswaps = _delegate;
    }

    fallback() external payable {
        (bool success, bytes memory data) = uniswaps.delegatecall(msg.data);
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