pragma solidity ^0.5.16;
pragma experimental ABIEncoderV2;

import "./Owned.sol";

/// @title OwnedMulticall
/// @dev Adapted from https://github.com/makerdao/multicall/
contract OwnedMulticall is Owned {
    struct Call {
        address target;
        bytes callData;
    }

    constructor(address _owner) public Owned(_owner) {}

    function aggregate(Call[] calldata calls) external onlyOwner returns (bytes[] memory returnData) {
        returnData = new bytes[](calls.length);
        for (uint256 i = 0; i < calls.length; i++) {
            (bool success, bytes memory ret) = calls[i].target.call(calls[i].callData);
            require(success);
            returnData[i] = ret;
        }
    }
}
