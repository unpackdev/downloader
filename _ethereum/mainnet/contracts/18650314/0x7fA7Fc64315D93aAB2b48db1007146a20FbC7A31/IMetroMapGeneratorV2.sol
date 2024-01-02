// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

//                        888
//                        888
//                        888
// 88888b.d88b.   .d88b.  888888 888d888 .d88b.
// 888 "888 "88b d8P  Y8b 888    888P"  d88""88b
// 888  888  888 88888888 888    888    888  888
// 888  888  888 Y8b.     Y88b.  888    Y88..88P
// 888  888  888  "Y8888   "Y888 888     "Y88P"

// 888                    d8b          888                          888
// 888                    Y8P          888                          888
// 888                                 888                          888
// 88888b.  888  888      888 88888b.  888888       8888b.  888d888 888888
// 888 "88b 888  888      888 888 "88b 888             "88b 888P"   888
// 888  888 888  888      888 888  888 888         .d888888 888     888
// 888 d88P Y88b 888      888 888  888 Y88b.       888  888 888     Y88b.
// 88888P"   "Y88888      888 888  888  "Y888      "Y888888 888      "Y888
//               888
//          Y8b d88P
//           "Y88P"

import "./IMetro.sol";
import "./IMetroThemeStorageV2.sol";

struct MetroStop {
    uint256 x;
    uint256 y;
}

struct MetroLine {
    MetroStop[] stops;
    uint256[] stopDirections;
}

struct MetroLineGroup {
    MetroLine[] lines;
}

struct MetroMapResult {
    MetroLineGroup[] lineGroups;
    uint256 stopCount;
    uint256 lineCount;
    bytes svg;
}

// mode: 
//  0 - Only map data
//  1 - Only SVG
interface IMetroMapGeneratorV2 {
    function generateMap(
        MetroTokenProperties memory tokenProperties,
        MetroThemeV2 memory theme,
        uint256 tokenId,
        uint256 mode
    ) external view returns (MetroMapResult memory);
}
