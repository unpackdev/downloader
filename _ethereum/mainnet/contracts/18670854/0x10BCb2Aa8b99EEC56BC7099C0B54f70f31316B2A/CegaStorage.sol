// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.17;

import "./Structs.sol";

contract CegaStorage {
    bytes32 private constant CEGA_STORAGE_POSITION =
        bytes32(uint256(keccak256("cega.global.storage")) - 1);

    function getStorage() internal pure returns (CegaGlobalStorage storage ds) {
        bytes32 position = CEGA_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }
}
