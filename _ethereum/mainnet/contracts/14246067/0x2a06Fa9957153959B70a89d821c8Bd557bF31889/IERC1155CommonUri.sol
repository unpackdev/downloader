// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// implemented by erc1155 tokens to allow burning
interface IERC1155CommonUri {

    function setCommonUri(uint256 uriId, string memory value) external;

    function setCommonUriOf(uint256 uriId, uint256 value) external;

    function getCommonUri(uint256 uriId) external view returns (string memory result);

    function commonUriOf(uint256 tokenHash) external view returns (string memory result);

    /// @notice mint tokens of specified amount to the specified address
    /// @param recipient the mint target
    /// @param tokenHash the token hash to mint
    /// @param amount the amount to mint
    function mintWithCommonUri(
        address recipient,
        uint256 tokenHash,
        uint256 amount,
        uint256 uriId
    ) external;

}
