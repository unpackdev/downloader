// SPDX-License-Identifier: UNLICENSED
// Copyright (c) 2022 GmDAO
pragma solidity >=0.8.0 <0.9.0;

import "./ERC165.sol";

import "./IGmStudioBlobStorage.sol";
import "./SSTORE2.sol";

/// @notice Canonical implementation of a blob storage contract.
/// @dev Stores data in contract bytecode.
contract GmStudioBlobStorage is ERC165, IGmStudioBlobStorage {
    address private immutable pointer;

    constructor(bytes memory code) {
        pointer = SSTORE2.write(code);
    }

    function getBlob() external view override returns (bytes memory) {
        return SSTORE2.read(pointer);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC165, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IGmStudioBlobStorage).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}
