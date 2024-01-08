//SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

interface INFT20Pair {
    function withdraw(
        uint256[] calldata _tokenIds,
        uint256[] calldata amounts,
        address recipient
    ) external;

    function withdraw(uint256[] calldata _tokenIds, uint256[] calldata amounts)
        external;

    function track1155(uint256 _tokenId) external returns (uint256);

    function swap721(uint256 _in, uint256 _out) external;

    function swap1155(
        uint256[] calldata in_ids,
        uint256[] calldata in_amounts,
        uint256[] calldata out_ids,
        uint256[] calldata out_amounts
    ) external;
}
