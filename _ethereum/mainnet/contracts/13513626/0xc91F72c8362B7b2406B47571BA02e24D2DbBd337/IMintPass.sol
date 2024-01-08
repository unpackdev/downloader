//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./IERC165.sol";
import "./IERC1155.sol";
import "./IAccessControl.sol";
import "./IERC2981.sol";


interface IMintPass is IERC1155, IERC2981 {


    function burn(
        address account,
        uint256 id,
        uint256 amount
    ) external;

    function burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory amounts
    ) external;

    function mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external;

    function mintBatch(
        address[] memory tos,
        uint256[] memory ids,
        uint256 amount,
        bytes memory data
    ) external;

}