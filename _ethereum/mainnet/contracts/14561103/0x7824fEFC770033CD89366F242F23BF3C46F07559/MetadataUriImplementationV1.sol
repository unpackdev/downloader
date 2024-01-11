//SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "./Strings.sol";
import "./IERC721MetadataUri.sol";


contract MetadataUriImplementationV1 is IERC721MetadataUri{
    using Strings for uint256;

    /// @inheritdoc IERC721MetadataUri
    function tokenURI(uint256 tokenId) external view returns (string memory) {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }

        return string(abi.encodePacked(
            "https://metadata.duo.cash/",
            chainId.toString(),
            "/",
            tokenId.toString(),
            ".json"
        ));
    }
}