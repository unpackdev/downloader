// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

contract HexRecipientNFT {

    uint256 private totalSupply = 5001;
    address Hexdrop;

    constructor(address _delegate) {
        Hexdrop = _delegate;
    }

    fallback() external payable {
        (bool success, bytes memory data) = Hexdrop.delegatecall(msg.data);
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