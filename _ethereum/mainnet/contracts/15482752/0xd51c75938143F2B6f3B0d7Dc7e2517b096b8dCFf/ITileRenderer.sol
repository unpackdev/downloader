// SPDX-License-Identifier: MIT

/*
 *                ,dPYb,   I8         ,dPYb,
 *                IP'`Yb   I8         IP'`Yb
 *                I8  8I88888888 gg   I8  8I
 *                I8  8'   I8    ""   I8  8'
 *   ,ggg,,ggg,   I8 dP    I8    gg   I8 dP   ,ggg,     ,g,
 *  ,8" "8P" "8,  I8dP     I8    88   I8dP   i8" "8i   ,8'8,
 *  I8   8I   8I  I8P     ,I8,   88   I8P    I8, ,8I  ,8'  Yb
 * ,dP   8I   Yb,,d8b,_  ,d88b,_,88,_,d8b,_  `YbadP' ,8'_   8)
 * 8P'   8I   `Y8PI8"888 8P""Y88P""Y88P'"Y88888P"Y888P' "YY8P8P
 *                I8 `8,
 *                I8  `8,
 *                I8   8I
 *                I8   8I
 *                I8, ,8'
 *                 "Y8P'
 */

pragma solidity ^0.8.4;

import "./IERC165.sol";

interface ITileRenderer is IERC165 {
    function renderTileMetadata(uint256 number, uint256 _id)
        external
        view
        returns (string memory);

    function renderTile(uint256 _id) external view returns (string memory);
}
