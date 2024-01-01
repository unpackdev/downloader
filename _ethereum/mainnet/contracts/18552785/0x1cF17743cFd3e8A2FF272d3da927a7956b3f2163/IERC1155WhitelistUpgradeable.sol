// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

interface IERC1155WhitelistUpgradeable {
    function mint(address to, uint256 id, uint256 amount, bytes memory data) external;

    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) external;
    /// @dev burn total amount that user hold
    /// @param to user address
    /// @param tokenId token id
    function burnTotalAmount(address to, uint256 tokenId) external;
}

interface IERC1155BurnableUpgradeable{
    function burn(address account, uint256 id, uint256 value) external;
}