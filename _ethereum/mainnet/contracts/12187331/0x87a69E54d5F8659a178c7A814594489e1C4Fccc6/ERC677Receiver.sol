// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.0;

// Based on https://github.com/smartcontractkit/LinkToken/blob/master/contracts/v0.6/token/ERC677Receiver.sol

abstract contract ERC677Receiver {
    function onTokenTransfer(
        address _sender,
        uint256 _value,
        bytes memory _data
    ) public virtual;
}
