// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface ISupply {
    /// @notice Emitted when the default max supply is changed
    /// @param oldMaxSupply The Default Max Supply before
    /// @param newMaxSupply The Default Max Supply after
    event DefaultMaxSupplyChanged(uint256 indexed oldMaxSupply, uint256 indexed newMaxSupply);

    /// @notice Emitted when the max supply on a given tokenId si changed
    /// @param tokenId The tokenId which max supply is being changed
    /// @param oldMaxSupply The max supply before being changed
    /// @param newMaxSupply The max supply after being changed
    event MaxSupplyChanged(
        uint256 indexed tokenId,
        uint256 indexed oldMaxSupply,
        uint256 indexed newMaxSupply
    );

    /// @notice Sets a new Default Max Supply
    /// @param value default max supply
    function setDefaultMaxSupply(uint256 value) external;

    /// @notice Returns the maximum supply allowed for a given id
    /// @param id Token Id
    /// @return Supply constraint for a given id
    function maxSupply(uint256 id) external view returns (uint256);

    /// @notice Set the maximum supply for a given token Id - Admin only
    /// @param supply The supply constraint
    /// @param tokenId The token Id
    function setMaxSupply(uint256 supply, uint256 tokenId) external;

    /// @notice Set the maximum supply for a list of token Ids - Admin only
    /// @param supplies The supply constraint list
    /// @param tokenIds The token Id list
    function setBatchMaxSupply(uint256[] calldata supplies, uint256[] calldata tokenIds)
        external;

    /// @notice Returns the total supply of a given token Id
    /// @param id Token Id
    /// @return Total amount of tokens with a given id
    function currentSupply(uint256 id) external view returns (uint256);

    /// @notice Indicates whether any token exist with a given id, or not.
    /// @param id Token Id
    /// @return boolean indicating if the supply is greather than 0
    function exists(uint256 id) external view returns (bool);
}
