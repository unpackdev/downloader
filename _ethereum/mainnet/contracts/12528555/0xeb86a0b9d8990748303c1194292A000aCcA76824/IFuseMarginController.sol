// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0;

/// @author Ganesh Gautham Elango
/// @title FuseMarginController Interface
interface IFuseMarginController {
    /// @dev Emitted when support of FuseMargin contract is added
    /// @param contractAddress Address of FuseMargin contract added
    /// @param owner User who added the contract
    event AddMarginContract(address indexed contractAddress, address owner);

    /// @dev Emitted when support of FuseMargin contract is removed
    /// @param contractAddress Address of FuseMargin contract removed
    /// @param owner User who removed the contract
    event RemoveMarginContract(address indexed contractAddress, address owner);

    /// @dev Emitted when support of Connector contract is added
    /// @param contractAddress Address of Connector contract added
    /// @param owner User who added the contract
    event AddConnectorContract(address indexed contractAddress, address owner);

    /// @dev Emitted when support of Connector contract is removed
    /// @param contractAddress Address of Connector contract removed
    /// @param owner User who removed the contract
    event RemoveConnectorContract(address indexed contractAddress, address owner);

    /// @dev Emitted when a new Base URI is added
    /// @param _metadataBaseURI URL for position metadata
    event SetBaseURI(string indexed _metadataBaseURI);

    /// @dev Creates a position NFT, to be called only from FuseMargin
    /// @param user User to give the NFT to
    /// @param position The position address
    /// @return tokenId of the position
    function newPosition(address user, address position) external returns (uint256);

    /// @dev Burns the position at the index, to be called only from FuseMargin
    /// @param tokenId tokenId of position to close
    function closePosition(uint256 tokenId) external returns (address);

    /// @dev Adds support for a new FuseMargin contract, to be called only from owner
    /// @param contractAddress Address of FuseMargin contract
    function addMarginContract(address contractAddress) external;

    /// @dev Removes support for a new FuseMargin contract, to be called only from owner
    /// @param contractAddress Address of FuseMargin contract
    function removeMarginContract(address contractAddress) external;

    /// @dev Adds support for a new Connector contract, to be called only from owner
    /// @param contractAddress Address of Connector contract
    function addConnectorContract(address contractAddress) external;

    /// @dev Removes support for a Connector contract, to be called only from owner
    /// @param contractAddress Address of Connector contract
    function removeConnectorContract(address contractAddress) external;

    /// @dev Modify NFT URL, to be called only from owner
    /// @param _metadataBaseURI URL for position metadata
    function setBaseURI(string memory _metadataBaseURI) external;

    /// @dev Gets all approved margin contracts
    /// @return List of the addresses of the approved margin contracts
    function getMarginContracts() external view returns (address[] memory);

    /// @dev Gets all tokenIds and positions a user holds, dont call this on chain since it is expensive
    /// @param user Address of user
    /// @return List of tokenIds the user holds
    /// @return List of positions the user holds
    function tokensOfOwner(address user) external view returns (uint256[] memory, address[] memory);

    /// @dev Gets a position address given an index (index = tokenId)
    /// @param tokenId Index of position
    /// @return position address
    function positions(uint256 tokenId) external view returns (address);

    /// @dev List of supported FuseMargin contracts
    /// @param index Get FuseMargin contract at index
    /// @return FuseMargin contract address
    function marginContracts(uint256 index) external view returns (address);

    /// @dev Check if FuseMargin contract address is approved
    /// @param contractAddress Address of FuseMargin contract
    /// @return true if approved, false if not
    function approvedContracts(address contractAddress) external view returns (bool);

    /// @dev Check if Connector contract address is approved
    /// @param contractAddress Address of Connector contract
    /// @return true if approved, false if not
    function approvedConnectors(address contractAddress) external view returns (bool);

    /// @dev Returns number of positions created
    /// @return Length of positions array
    function positionsLength() external view returns (uint256);
}
