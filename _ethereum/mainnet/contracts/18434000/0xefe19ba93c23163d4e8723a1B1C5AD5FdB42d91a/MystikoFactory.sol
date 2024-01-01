//SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./INFT.sol";
import "./IFactory.sol";

import "./Clones.sol";
import "./AccessControl.sol";
import "./EnumerableSet.sol";

contract MystikoFactory is AccessControl, IFactory {
    using EnumerableSet for EnumerableSet.AddressSet;

    bytes32 public constant SIGNER_ROLE = keccak256("SIGNER_ROLE");

    address public implementation;
    string public baseURI;

    EnumerableSet.AddressSet private _createdCollections;

    event CreatedCollection(address indexed collection, uint256 id);

    constructor(address _owner, string memory _baseURI) {
        require(_owner != address(0), "MystikoFactory: zero address");
        baseURI = _baseURI;
        _setupRole(DEFAULT_ADMIN_ROLE, _owner);
    }

    /**
     * @dev one-time function for setting NFT implementation
     * @notice only owner available
     * @param value NFT-template address
     */
    function setImplementation(
        address value
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(
            value != address(0) && implementation == address(0),
            "MystikoFactory: already initialized"
        );
        implementation = value;
    }

    /**
     * @dev URI base changer
     * @notice only owner available
     * @param _baseURI new base URI
     */
    function changeBaseURI(
        string memory _baseURI
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        baseURI = _baseURI;
    }

    /**
     * @dev method to deploy new NFT collection
     * @param name collection name
     * @param symbol collection symbol
     * @param totalSupply collection totalSupply
     * @param expirationTime when mint will be available
     */
    function createCollection(
        string memory name,
        string memory symbol,
        uint256 totalSupply,
        uint256 expirationTime,
        uint256 id
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(
            implementation != address(0),
            "MystikoFactory: not initialized"
        );
        require(
            totalSupply > 0 && expirationTime > block.timestamp,
            "MystikoFactory: wrong params"
        );

        address createdCollection = Clones.clone(implementation);
        INFT(createdCollection).initialize(
            name,
            symbol,
            totalSupply,
            expirationTime
        );
        _createdCollections.add(createdCollection);

        emit CreatedCollection(createdCollection, id);
    }

    /**
     * @dev view function to get addresses of all created collections
     * @return an array of all created collections
     */
    function getCreatedCollections() external view returns (address[] memory) {
        return _createdCollections.values();
    }

    /**
     * @dev function for NFT-template to get address role
     * @param wallet address
     * @return is signer
     * @return is admin
     */
    function isSignerOrAdmin(address wallet) external view override returns (bool, bool) {
        return (hasRole(SIGNER_ROLE, wallet), hasRole(DEFAULT_ADMIN_ROLE, wallet));
    }
}
