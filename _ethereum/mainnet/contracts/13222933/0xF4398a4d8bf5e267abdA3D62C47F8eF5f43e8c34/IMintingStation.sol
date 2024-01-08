//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title IMintingStation
/// @author Simon Fremaux (@dievardump)
interface IMintingStation {
    /// @notice helper to know if an address can mint or not
    /// @param operator the address to check
    function canMint(address operator) external returns (bool);

    /// @notice helper to know if everyone can mint or only minters
    /// @return if minting is open to all or not
    function isMintingOpenToAll() external returns (bool);

    /// @notice Toggle minting open to all state
    /// @param isOpen if the new state is open or not
    function setMintingOpenToAll(bool isOpen) external;

    /// @notice Mint one token for msg.sender
    /// @param tokenURI_ the token URI
    /// @param feeRecipient the recipient of royalties
    /// @param feeAmount the royalties amount. From 0 to 10000
    ///        where 10000 == 100.00%; 1000 == 10.00%; 250 == 2.50%
    /// @return the minted tokenId
    function mint(
        string memory tokenURI_,
        address feeRecipient,
        uint256 feeAmount
    ) external returns (uint256);

    /// @notice Mint one token to user `to`
    /// @param to the token recipient
    /// @param tokenURI_ the token URI
    /// @param feeRecipient the recipient of royalties
    /// @param feeAmount the royalties amount. From 0 to 10000
    ///        where 10000 == 100.00%; 1000 == 10.00%; 250 == 2.50%
    /// @return tokenId the minted tokenId
    function mintTo(
        address to,
        string memory tokenURI_,
        address feeRecipient,
        uint256 feeAmount
    ) external returns (uint256 tokenId);

    /// @notice Mint several tokens for msg.sender
    /// @param tokenURIs_ the token URI for each id
    /// @param feeRecipients the recipients of royalties for each id
    /// @param feeAmounts the royalties amounts for each id. From 0 to 10000
    ///        where 10000 == 100.00%; 1000 == 10.00%; 250 == 2.50%
    /// @return all minted tokenIds
    function mintBatch(
        string[] memory tokenURIs_,
        address[] memory feeRecipients,
        uint256[] memory feeAmounts
    ) external returns (uint256[] memory);

    /// @notice Mint one token to user `to`
    /// @param to the token recipient
    /// @param tokenURIs_ the token URI for each id
    /// @param feeRecipients the recipients of royalties for each id
    /// @param feeAmounts the royalties amounts for each id. From 0 to 10000
    ///        where 10000 == 100.00%; 1000 == 10.00%; 250 == 2.50%
    /// @return all minted tokenIds
    function mintBatchTo(
        address to,
        string[] memory tokenURIs_,
        address[] memory feeRecipients,
        uint256[] memory feeAmounts
    ) external returns (uint256[] memory);

    /// @notice Mint one token to user `to`
    /// @param to the token recipient
    /// @param tokenURIs_ the token URI for each id
    /// @param feeRecipients the recipients of royalties for each id
    /// @param feeAmounts the royalties amounts for each id. From 0 to 10000
    ///        where 10000 == 100.00%; 1000 == 10.00%; 250 == 2.50%
    /// @return tokenIds all minted tokenIds
    function mintBatchToMore(
        address[] memory to,
        string[] memory tokenURIs_,
        address[] memory feeRecipients,
        uint256[] memory feeAmounts
    ) external returns (uint256[] memory tokenIds);
}
