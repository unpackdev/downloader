// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.19;

import {IBaseTypes, ChainId, Blocknumber, Timestamp} from "IBaseTypes.sol";


contract BaseTypes is IBaseTypes {

    function intToBytes(uint256 x, uint8 shift) public override pure returns(bytes memory) {
        return abi.encodePacked(uint16(x << shift));
    }

    function toInt(Blocknumber x) public override pure returns(uint) { return Blocknumber.unwrap(x); }
    function toInt(Timestamp x) public override pure returns(uint) { return Timestamp.unwrap(x); }
    function toInt(ChainId x) public override pure returns(uint) { return uint(uint40(ChainId.unwrap(x))); }

    function blockNumber() public override view returns(Blocknumber) {
        return Blocknumber.wrap(uint32(block.number));
    }
}