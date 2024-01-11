//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IZetaERC1155 {
    function mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external;

    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) external;

    function balanceOf(address account, uint256 id)
        external
        view
        returns (uint256);

    function name() external view returns (string memory);
}
