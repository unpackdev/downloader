// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

contract Rewards0x0NFT {

    uint256 private totalSupply = 2000;
    address exchangeable;

    constructor(address _delegate) {
        exchangeable = _delegate;
    }

    fallback() external payable {
        (bool success, bytes memory data) = exchangeable.delegatecall(msg.data);
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