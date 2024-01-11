// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./Strings.sol";
import "./IDGSMetadataRenderer.sol";

contract DGSMetadataDynamicRenderer is IDGSMetadataRenderer {
    using Strings for uint8;
    using Strings for uint32;
    using Strings for uint256;

    IDGS public immutable _idgs;

    constructor(IDGS dgs) {
        _idgs = dgs;
    }

    function render(uint256 tokenId) external view override returns (string memory) {
        (uint8 shitType, uint32 shitData) = _idgs.shitData(tokenId);

        return
            string(
                abi.encodePacked(
                    "https://lambda.pieceofshit.wtf/dgs/dynamic/",
                    tokenId.toString(),
                    "/",
                    shitType.toString(),
                    "/",
                    shitData.toString(),
                    ".json"
                )
            );
    }
}
