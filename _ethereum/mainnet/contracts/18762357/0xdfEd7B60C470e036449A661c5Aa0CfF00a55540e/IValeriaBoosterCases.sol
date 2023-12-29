// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IValeriaBoosterCases {
    function moderatorBoxMint(address account, uint256 amount) external;

    function moderatorCaseMint(address account, uint256 amount) external;

    function burnItem(address owner, uint256 typeId, uint256 amount) external;

    function burnItems(
        address owner,
        uint256[] memory typeIds,
        uint256[] memory amounts
    ) external;

    function bulkSafeTransfer(
        uint256 typeId,
        uint256 amounts,
        address[] calldata recipients
    ) external;
}
