// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.20;

interface IUserVault {
    /// @notice Mint a new vault to msg.sender
    /// @return newId The id of the new vault
    function mint() external returns (uint256);

    /// @notice Burn a vault and return all assets to owner.
    function burn(uint256 _vaultId, address _assetRecipient) external;

    /// @notice Burn a vault and return all assets to owner.
    /// @param _vaultId The vault to burn.
    /// @param _collections The NFT collections to burn.
    /// @param _tokenIds The NFT token IDs to burn.
    /// @param _tokens The ERC20 tokens to burn.
    function burnAndWithdraw(
        uint256 _vaultId,
        address[] calldata _collections,
        uint256[] calldata _tokenIds,
        address[] calldata _tokens
    ) external;

    /// @notice Get the vault owner of an NFT. Will return 0 if none.
    /// @param _collection The NFT collection.
    /// @param _tokenId The NFT token ID.
    /// @return vaultId The vault owning the NFT.
    function ERC721OwnerOf(address _collection, uint256 _tokenId) external view returns (uint256);

    /// @notice Get the balance for a given token for a given vault. address(0) = ETH
    /// @param _vaultId The vault to check.
    /// @param _token The token to check.
    /// @return Balance The balance of the token in the vault.
    function ERC20BalanceOf(uint256 _vaultId, address _token) external view returns (uint256);

    /// @notice Deposit an NFT into the vault.
    /// @param _vaultId The vault to deposit into.
    /// @param _collection The NFT collection.
    /// @param _tokenId The NFT token ID.
    function depositERC721(uint256 _vaultId, address _collection, uint256 _tokenId) external;

    /// @notice Deposit multiple NFTs.
    /// @param _vaultId The vault to deposit into.
    /// @param _collection The NFT collection.
    /// @param _tokenIds The NFT token IDs.
    function depositERC721s(uint256 _vaultId, address _collection, uint256[] calldata _tokenIds) external;

    /// @notice Deposit an ERC20 token into the vault.
    /// @param _vaultId The vault to deposit into.
    /// @param _token The ERC20 token.
    /// @param _amount The amount to deposit.
    function depositERC20(uint256 _vaultId, address _token, uint256 _amount) external;

    /// @notice Deposit ETH into the vault.
    /// @param _vaultId The vault to deposit into.
    function depositEth(uint256 _vaultId) external payable;

    /// @notice Withdraw an NFT from the vault.
    /// @param _vaultId The vault to withdraw from.
    /// @param _collection The NFT collection.
    /// @param _tokenId The NFT token ID.
    function withdrawERC721(uint256 _vaultId, address _collection, uint256 _tokenId) external;

    /// @notice Withdraw multiple NFTs.
    /// @param _vaultId The vault to withdraw from.
    /// @param _collections The NFT collections.
    /// @param _tokenIds The NFT token IDs.
    function withdrawERC721s(uint256 _vaultId, address[] calldata _collections, uint256[] calldata _tokenIds)
        external;

    /// @notice Withdraw an ERC20 token from the vault.
    /// @param _vaultId The vault to withdraw from.
    /// @param _token The ERC20 token.
    function withdrawERC20(uint256 _vaultId, address _token) external;

    /// @notice Withdraw ERC20s from the vault.
    /// @param _vaultId The vault to withdraw from.
    /// @param _tokens The ERC20 tokens.
    function withdrawERC20s(uint256 _vaultId, address[] calldata _tokens) external;

    /// @notice Withdraw ETH from the vault.
    /// @param _vaultId The vault to withdraw from.
    function withdrawEth(uint256 _vaultId) external;
}
