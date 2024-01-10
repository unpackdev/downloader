// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// implemented by erc1155 tokens to allow mminting
interface IERC1155Owned {

    /// @notice returns the owned tokens of the account
    /// @param owner the owner address
    /// @param ids owned token ids
    function owned(address owner) external view returns (uint256[] memory ids);

    /// @notice returns whether given id is owned by the account
    /// @param account tthe account
    /// @param toCheck the token id to check
    /// @param isOwner whether the given address is owner of the token id
    function isOwnerOf(address account, uint256 toCheck) external view returns (bool isOwner);

}
