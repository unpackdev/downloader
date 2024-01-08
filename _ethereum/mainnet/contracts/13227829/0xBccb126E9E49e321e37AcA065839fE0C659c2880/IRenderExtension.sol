//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

interface IRenderExtension is IERC165 {
    struct GenerateResult {
        string svgPart;
        string attributes;
    }

    struct Attribute {
        string displayType;
        string traitType;
        string value;
    }

    function generate(uint256 tokenId, uint256 generationId) external view returns (GenerateResult memory generateResult);
}
