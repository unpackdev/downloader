// SPDX-License-Identifier: Unlicensed
pragma solidity ~0.8.13;

import "./IERC2981Upgradeable.sol";
import "./IERC721MetadataUpgradeable.sol";
import "./IAccessControlUpgradeable.sol";
import "./IMintable.sol";
import "./IExtensionManager.sol";

interface IStoryversePlot is
    IERC2981Upgradeable,
    IERC721MetadataUpgradeable,
    IAccessControlUpgradeable,
    IMintable
{
    /// @notice Emitted when a new extension manager is set
    /// @param who Admin that set the extension manager
    /// @param extensionManager New extension manager contract
    event ExtensionManagerSet(address indexed who, address indexed extensionManager);

    /// @notice Emitted when a new Immutable X is set
    /// @param who Admin that set the extension manager
    /// @param imx New Immutable X address
    event IMXSet(address indexed who, address indexed imx);

    /// @notice Emitted when a new token is minted and a blueprint is set
    /// @param to Owner of the newly minted token
    /// @param tokenId Token ID that was minted
    /// @param blueprint Blueprint extracted from the blob
    event AssetMinted(address to, uint256 tokenId, bytes blueprint);

    /// @notice Emitted when the new base URI is set
    /// @param who Admin that set the base URI
    event BaseURISet(address indexed who);

    /// @notice Emitted when funds are withdrawn from the contract
    /// @param to Recipient of the funds
    /// @param amount Amount sent in Wei
    event FundsWithdrawn(address to, uint256 amount);

    /// @notice Get the base URI
    /// @return uri_ Base URI
    function baseURI() external returns (string memory uri_);

    /// @notice Get the extension manager
    /// @return extensionManager_ Extension manager
    function extensionManager() external returns (IExtensionManager extensionManager_);

    /// @notice Get the Immutable X address
    /// @return imx_ Immutable X address
    function imx() external returns (address imx_);

    /// @notice Get the blueprint for a token ID
    /// @param _tokenId Token ID
    /// @return blueprint_ Blueprint
    function blueprints(uint256 _tokenId) external returns (bytes memory blueprint_);

    /// @notice Sets a new extension manager
    /// @param _extensionManager New extension manager
    function setExtensionManager(address _extensionManager) external;

    /// @notice Mint a new token
    /// @param _to Owner of the newly minted token
    /// @param _tokenId Token ID
    function safeMint(address _to, uint256 _tokenId) external;

    /// @notice Sets a base URI
    /// @param _uri Base URI
    function setBaseURI(string calldata _uri) external;

    /// @notice Get PLOT data for the token ID
    /// @param _tokenId Token ID
    /// @param _in Input data
    /// @return out_ Output data
    function getPLOTData(uint256 _tokenId, bytes memory _in) external returns (bytes memory out_);

    /// @notice Sets PLOT data for the token ID
    /// @param _tokenId Token ID
    /// @param _in Input data
    /// @return out_ Output data
    function setPLOTData(uint256 _tokenId, bytes memory _in) external returns (bytes memory out_);

    /// @notice Pays for PLOT data of the token ID
    /// @param _tokenId Token ID
    /// @param _in Input data
    /// @return out_ Output data
    function payPLOTData(uint256 _tokenId, bytes memory _in)
        external
        payable
        returns (bytes memory out_);

    /// @notice Get data
    /// @param _in Input data
    /// @return out_ Output data
    function getData(bytes memory _in) external returns (bytes memory out_);

    /// @notice Sets data
    /// @param _in Input data
    /// @return out_ Output data
    function setData(bytes memory _in) external returns (bytes memory out_);

    /// @notice Pays for data
    /// @param _in Input data
    /// @return out_ Output data
    function payData(bytes memory _in) external payable returns (bytes memory out_);

    /// @notice Transfers the ownership of the contract
    /// @param newOwner New owner of the contract
    function transferOwnership(address newOwner) external;

    /// @notice Sets the Immutable X address
    /// @param _imx New Immutable X
    function setIMX(address _imx) external;

    /// @notice Withdraw funds from the contract
    /// @param _to Recipient of the funds
    /// @param _amount Amount sent, in Wei
    function withdrawFunds(address payable _to, uint256 _amount) external;
}
