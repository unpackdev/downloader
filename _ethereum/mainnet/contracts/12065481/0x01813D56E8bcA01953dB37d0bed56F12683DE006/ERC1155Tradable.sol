// SPDX-License-Identifier: MIT
pragma solidity =0.6.12;
pragma experimental ABIEncoderV2;

import "./AccessControl.sol";
import "./Ownable.sol";

// OpenSea ProxyRegistry Interface
// import "./IProxyRegistry.sol";
import "./IProxyRegistry.sol";

// ERC1155 Interfaces
import "./ERC1155.sol";
import "./ERC1155MintBurn.sol";
import "./ERC1155Metadata.sol";

contract ERC1155Tradable is
    ERC1155,
    ERC1155MintBurn,
    ERC1155Metadata,
    AccessControl
{
    /***********************************|
    |   Constants                       |
    |__________________________________*/
    // Items Metadata
    string public name;
    string public symbol;

    // Access Control
    bytes32 public constant CONTROLLER_ROLE = keccak256("CONTROLLER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    // Internals
    uint256 internal _currentTokenID = 0;

    // Token Metadata
    mapping(uint256 => address) public creators;
    mapping(uint256 => uint256) public tokenSupply;
    mapping(uint256 => uint256) public tokenMaxSupply;

    // Native IPFS Support
    bool public ipfsURIs = false;
    mapping(uint256 => string) public ipfs;

    // OpenSea Integration
    address proxyRegistryAddress;

    constructor(
        string memory _name,
        string memory _symbol,
        address _proxyRegistryAddress
    ) public {
        name = _name;
        symbol = _symbol;
        proxyRegistryAddress = _proxyRegistryAddress;

        // Setup Role Management
        _setRoleAdmin(CONTROLLER_ROLE, CONTROLLER_ROLE);
        _setRoleAdmin(MINTER_ROLE, CONTROLLER_ROLE);

        // Set Initial Controller as Contract Deployer
        _setupRole(CONTROLLER_ROLE, msg.sender);
    }

    /***********************************|
    |   Events                          |
    |__________________________________*/
    /**
     * @dev A new item is created.
     */
    event ItemCreated(
        uint256 id,
        uint256 tokenInitialSupply,
        uint256 tokenMaxSupply,
        string ipfs
    );

    /**
     * @dev An item is updated.
     */
    event ItemUpdated(uint256 id, string ipfs);

    /***********************************|
    |   Items                           |
    |__________________________________*/

    /**
     * @dev Returns the total quantity for a token ID
     * @param _id uint256 ID of the token to query
     * @return amount of token in existence
     */
    function totalSupply(uint256 _id) public view returns (uint256) {
        return tokenSupply[_id];
    }

    /**
     * @dev Returns the max quantity for a token ID
     * @param _id uint256 ID of the token to query
     * @return amount of token in existence
     */
    function maxSupply(uint256 _id) public view returns (uint256) {
        return tokenMaxSupply[_id];
    }

    /**
     * @dev Creates a new token type and assigns _initialSupply to an address
     * @param _maxSupply max supply allowed
     * @param _initialSupply Optional amount to supply the first owner
     * @param _uri Optional URI for this token type
     * @param _data Optional data to pass if receiver is contract
     * @return _id The newly created token ID
     */
    function create(
        uint256 _initialSupply,
        uint256 _maxSupply,
        string calldata _uri,
        bytes calldata _data,
        string calldata _ipfs
    ) public returns (uint256 _id) {
        // Minter Role Required
        require(hasRole(MINTER_ROLE, msg.sender), "Unauthorized");

        // Sanity Check
        require(0 < _maxSupply, "Insufficient Max Supply");
        require(_initialSupply <= _maxSupply, "Invalid Initial Supply");

        // Calculate Token ID
        _id = _getNextTokenID();
        _incrementTokenTypeId();

        // Unique Item URI
        if (bytes(_uri).length > 0) {
            emit URI(_uri, _id);
        }

        // Mint Token if Initial Supply Above Zero
        if (_initialSupply != 0) {
            super._mint(msg.sender, _id, _initialSupply, _data);
        }

        // Item Mappings
        creators[_id] = msg.sender;
        tokenMaxSupply[_id] = _maxSupply;
        tokenSupply[_id] = _initialSupply;

        // IPFS Mapping
        ipfs[_id] = _ipfs;

        emit ItemCreated(_id, _initialSupply, _maxSupply, _ipfs);
        return _id;
    }

    /**
     * @dev Creates a new token type and assigns _initialSupply to an address
     * @param _maxSupply max supply allowed
     * @param _initialSupply Optional amount to supply the first owner
     * @param _uri Optional URI for this token type
     * @param _data Optional data to pass if receiver is contract
     * @return _id The newly created token ID
     */
    function createBatch(
        uint256[] calldata _initialSupply,
        uint256[] calldata _maxSupply,
        string[] calldata _uri,
        bytes[] calldata _data,
        string[] calldata _ipfs
    ) external returns (bool) {
        // Minter Role Required
        require(hasRole(MINTER_ROLE, msg.sender), "Unauthorized");

        // Iterate Items
        for (uint256 index = 0; index < _initialSupply.length; index++) {
            create(
                _initialSupply[index],
                _maxSupply[index],
                _uri[index],
                _data[index],
                _ipfs[index]
            );
        }

        return true;
    }

    /**
     * @dev Mint _value of tokens of a given id
     * @param _to The address to mint tokens to.
     * @param _id token id to mint
     * @param _amount The amount to be minted
     * @param _data Data to be passed if receiver is contract
     */
    function mint(
        address _to,
        uint256 _id,
        uint256 _amount,
        bytes memory _data
    ) public returns (bool) {
        // Minter Role Required
        require(hasRole(MINTER_ROLE, msg.sender), "Unauthorized");

        // Check Max Supply
        require(
            tokenSupply[_id].add(_amount) <= tokenMaxSupply[_id],
            "Max Supply Reached"
        );

        // Update Item Amount
        tokenSupply[_id] = tokenSupply[_id].add(_amount);

        // Mint Item
        super._mint(_to, _id, _amount, _data);

        return true;
    }

    /***********************************|
    |   Item Metadata                   |
    |__________________________________*/

    /**
     * @notice A distinct Uniform Resource Identifier (URI) for a given token.
     * @dev URIs are defined in RFC 3986.
     *      Override default URI specification for mapping to IPFS hash
     * @param _id item id
     * @return URI string
     */
    function uri(uint256 _id) public view returns (string memory) {
        require(_exists(_id), "ERC1155Tradable#uri: NONEXISTENT_TOKEN");
        return
            ipfsURIs
                ? string(abi.encodePacked("ipfs://", ipfs[_id]))
                : super._uri(_id);
    }

    /**
     * @notice Toggle IPFS mapping used as tokenURI
     * @dev Toggle IPFS mapping used as tokenURI
     * @return ipfsURIs bool
     */
    function toggleIPFS() external returns (bool) {
        require(hasRole(CONTROLLER_ROLE, msg.sender));
        ipfsURIs = ipfsURIs ? false : true;
        return ipfsURIs;
    }

    /**
     * @notice Batch Update Item URIs
     * @param _ids Array of item ids
     * @param _newBaseMetadataURI New base URL of token's URI
     */
    function updateItemsURI(
        uint256[] calldata _ids,
        string memory _newBaseMetadataURI
    ) external returns (bool) {
        require(hasRole(CONTROLLER_ROLE, msg.sender));
        if (bytes(_newBaseMetadataURI).length > 0) {
            super._setBaseMetadataURI(_newBaseMetadataURI);
        }
        super._logURIs(_ids);
    }

    /**
     * @dev Will update the base URL of token's URI
     * @param _newBaseMetadataURI New base URL of token's URI
     */
    function setBaseMetadataURI(string memory _newBaseMetadataURI) external {
        require(hasRole(CONTROLLER_ROLE, msg.sender));
        super._setBaseMetadataURI(_newBaseMetadataURI);
    }

    /***********************************|
    |   Item Transfers                  |
    |__________________________________*/

    /**
     * Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-free listings.
     */
    function isApprovedForAll(address _owner, address _operator)
        public
        view
        override
        returns (bool isOperator)
    {
        // Whitelist OpenSea proxy contract for easy trading.
        IProxyRegistry proxyRegistry = IProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(_owner)) == _operator) {
            return true;
        }

        return ERC1155.isApprovedForAll(_owner, _operator);
    }

    /***********************************|
    |   Helpers                         |
    |__________________________________*/

    /**
     * @notice Check item exists using creators
     * @dev Returns whether the specified token exists by checking to see if it has a creator
     * @param _id uint256 ID of the token to query the existence of
     * @return bool whether the token exists
     */
    function _exists(uint256 _id) internal view returns (bool) {
        return creators[_id] != address(0);
    }

    /**
     * @dev calculates the next token ID based on value of _currentTokenID
     * @return uint256 for the next token ID
     */
    function _getNextTokenID() internal view returns (uint256) {
        return _currentTokenID.add(1);
    }

    /**
     * @dev increments the value of _currentTokenID
     */
    function _incrementTokenTypeId() internal {
        _currentTokenID++;
    }

    /***********************************|
    |   ERC165                          |
    |__________________________________*/
    bytes4 private constant INTERFACE_SIGNATURE_ERC165 = 0x01ffc9a7;
    bytes4 private constant INTERFACE_SIGNATURE_ERC1155 = 0xd9b67a26;

    function supportsInterface(bytes4 _interfaceID)
        public
        pure
        override(ERC1155, ERC1155Metadata)
        returns (bool)
    {
        if (
            _interfaceID == INTERFACE_SIGNATURE_ERC165 ||
            _interfaceID == INTERFACE_SIGNATURE_ERC1155
        ) {
            return true;
        }
        return false;
    }
}
