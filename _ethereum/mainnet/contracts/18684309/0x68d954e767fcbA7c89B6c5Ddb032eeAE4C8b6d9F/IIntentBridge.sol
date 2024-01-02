// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;

interface IIntentBridge {
    function bridgeETH(uint16 _dstChainId, address _dstToken, address _from, address _to, uint256 _amount) external payable;
}
