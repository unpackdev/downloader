//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./Strings.sol";
import "./Coordinates.sol";

/// @title Coordinates Metadata
/// @notice https://coordinates.folia.app
/// @author @okwme
/// @dev The updateable and replaceable metadata contract for Coordinates

contract Metadata is Ownable {
    constructor() {}

    string public baseURI =
        "ipfs://QmNgDSXzx28jWmtVBS1MDMgboMGULjhdtL1gDWFJu8FSmC/";

    /// @dev sets the baseURI can only be called by the owner
    /// @param baseURI_ the new baseURI
    function setbaseURI(string memory baseURI_) public onlyOwner {
        baseURI = baseURI_;
    }

    /// @dev generates the metadata
    /// @param tokenId the tokenId
    /// @return _ the metadata
    function getMetadata(uint256 tokenId) public view returns (string memory) {
        return
            string(
                abi.encodePacked(baseURI, Strings.toString(tokenId), ".json")
            );
    }
}
