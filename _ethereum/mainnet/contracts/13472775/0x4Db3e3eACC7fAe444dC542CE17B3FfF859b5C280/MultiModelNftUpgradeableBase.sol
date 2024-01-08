// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.7.6;
pragma abicoder v2;

import "./AccessControlUpgradeable.sol";
import "./IERC20Upgradeable.sol";

import "./OwnableUpgradeable.sol";
import "./OpenseaERC721Upgradeable.sol";
import "./IPriceOracleUpgradeable.sol";
import "./INymLib.sol";

contract MultiModelNftUpgradeableBase is OwnableUpgradeable, OpenseaERC721Upgradeable, AccessControlUpgradeable {

    struct Model {
        // Bonus percent of the model
        uint8 bonus;
        // Class of the model
        uint8 class;
        // Name of the model
        string name;
        // URI of the model
        string metafileUri;
        // Capacity mintable by user
        uint256 capacity;
        // Count of token of the model
        uint256 supply;
        // Minting price in ETH
        uint256 mintPrice;
        // Default color of the model
        bytes4[] defaultColor;
        // Capacity of airdrop
        uint256 airdropCapacity;
        // Count of token airdropped
        uint256 airdropSupply;
    }

    INymLib public nymLib;
    IPriceOracleUpgradeable public priceOracle;

    uint256 internal _currentTokenId = 0;

    /// @notice The address of the GridZone token
    IERC20Upgradeable public zoneToken;

    // Mapping from token ID to name
    mapping (uint256 => string) internal _tokenName;
    // Mapping if certain name string has already been reserved
    mapping (string => bool) internal _nameReserved;
    // Option to changeable name
    bool public nameChangeable;

    // Option to changeable color
    bool public colorChangeable;
    // Mapping if certain name string has already been reserved
    mapping (uint256 => bytes4[]) internal _colors;

    // Array of models
    Model[] public models;
    // Mapping from token ID to model ID
    mapping (uint256 => uint256) public modelIds;

    // The nonce for airdrop.
    mapping(address => uint256) public airdropNonces;

    // Address of sub-implementation contract
    address public subImpl;

    bytes32 public constant ALLOWED_MINTERS = keccak256("ALLOWED_MINTERS");

    function _msgSender() internal override view returns (address payable) {
        return EIP712MetaTxUpgradeable.msgSender();
    }

    function modelCount() public view returns (uint256) {
        return models.length;
    }

    uint256[38] private __gap;
}
