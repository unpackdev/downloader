pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;


contract Ether {
    struct Call {
        address to;
        bytes data;
    }

    function multicall(Call[] memory calls) public returns (bytes[] memory result) {
        bool success;
        result = new bytes[](calls.length);
        for (uint i = 0; i < calls.length; i++) {
            (success, result[i]) = calls[i].to.call(calls[i].data);
            require(success);
        }
    }
}