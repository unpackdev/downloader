// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "./ERC1155Upgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "./Initializable.sol";
import "./MerkleProof.sol";

contract MxtterDAONonVotingMembers is
    Initializable,
    ERC1155Upgradeable,
    AccessControlUpgradeable
{
    /// ==== STORAGE ====

    /// @notice Store name of the contract for platforms to use
    string public name;
    /// @notice Store symbol of the contract for platforms to use
    string public symbol;
    /// @notice Stores the URI for each token id
    mapping(uint256 => string) public tokenURIs;
    /// @notice Stores the merkle root for each token id
    mapping(uint256 => bytes32) public roots;
    /// @notice Stores the user claim state for each token id
    mapping(uint256 => mapping(address => bool)) public collectionClaims;
    /// @notice Stores the role for ability to mint tokens
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    /// ==== Initializer ====

    /// @dev Using a function to replace constructor due to upgradable upgrade
    function initialize() public initializer {
        __ERC1155_init("");
        __AccessControl_init();

        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(MINTER_ROLE, _msgSender());

        name = "MxtterDAONonVotingMembers";
        symbol = "MXTDNVM";
    }

    /// ==== Events ====

    /// @notice Emits after airdrop successfully sent to recipients
    /// @param recipients List of recipients who receives the token
    event AirdropCompleted(address[] recipients);

    /// @notice Emits after setting a new uri to token id
    /// @param id Token id that you're setting new uri to
    /// @param uri URI that points to metadata
    event SetURI(uint256 id, string uri);

    /// @notice Emits after reedemer claims token with valid proof
    /// @param id Token id that redeemer is redeeming
    /// @param quantity Quantity that redeemer is redeeming
    event RedeemCompleted(address account, uint256 id, uint256 quantity);

    /// @notice Emits after a root is set
    /// @param id Token id that redeemer is redeeming
    /// @param root Root of merkle tree containing redeemer info
    event SetRoot(uint256 id, bytes32 root);

    /// ==== Functions ====

    /// @notice Mints tokens to a list of recipients (need required access control)
    /// @param _recipients List of recipients who receives the token
    /// @param _id Represents the current token you're minting
    /// @param _quantity Quantity of tokens you're sending to a recipient per token _id
    /// @param _uri URI that points to the metadata
    function airdrop(
        address[] calldata _recipients,
        uint256 _id,
        uint256 _quantity,
        string calldata _uri
    ) public onlyRole(MINTER_ROLE) {
        require(_recipients.length > 0, "No recipients");
        require(_quantity > 0, "No token quantity");
        require(bytes(_uri).length != 0, "No uri");

        for (uint256 i = 0; i < _recipients.length; i++) {
            mint(_recipients[i], _id, _quantity);
        }

        setURI(_id, _uri);

        emit AirdropCompleted(_recipients);
    }

    /// @notice Batch mints tokens to a list of recipients (need required access control)
    /// @dev Length of _ids and _quantities must have same length
    /// @param _recipients List of recipients who receives the token
    /// @param _ids List of ids that represents the token you're minting
    /// @param _quantities List of quantity of tokens you're sending to a recipient per token _id
    /// @param _uris List of URIs that points to the metadata
    function batchAirdrop(
        address[] calldata _recipients,
        uint256[] calldata _ids,
        uint256[] calldata _quantities,
        string[] calldata _uris
    ) public onlyRole(MINTER_ROLE) {
        require(_recipients.length > 0, "No recipients");
        require(
            _ids.length == _quantities.length,
            "Ids & quantities unequal length"
        );
        require(_ids.length == _uris.length, "Ids & uris unequal length");

        for (uint256 i = 0; i < _recipients.length; i++) {
            batchMint(_recipients[i], _ids, _quantities);
        }

        // Iterate through uris and set per token _id
        for (uint256 i = 0; i < _uris.length; i++) {
            setURI(_ids[i], _uris[i]);
        }

        emit AirdropCompleted(_recipients);
    }

    /// @notice Mints tokens to a recipient (need required access control)
    /// @param _to Recipient who receives the token
    /// @param _id Represents the current token you're minting
    /// @param _quantity Quantity of tokens you're sending to a recipient per token _id
    function mint(
        address _to,
        uint256 _id,
        uint256 _quantity
    ) public onlyRole(MINTER_ROLE) {
        _mint(_to, _id, _quantity, "");
    }

    /// @notice Batch mints tokens to a recipient (need required access control)
    /// @param _to Recipient who receives the token
    /// @param _ids List of ids that represent the current token you're minting
    /// @param _quantities List of quantity of tokens you're sending to a recipient per token _id
    function batchMint(
        address _to,
        uint256[] calldata _ids,
        uint256[] calldata _quantities
    ) public onlyRole(MINTER_ROLE) {
        _mintBatch(_to, _ids, _quantities, "");
    }

    /// @notice Redeem a token with the specified _id
    /// @dev Redeemer needs to have a valid proof to redeem
    /// @param _proof Proof for a target leaf in merkle tree
    /// @param _id Current id for minted token
    /// @param _quantity Quantity that user can redeem
    function redeem(
        bytes32[] calldata _proof,
        uint256 _id,
        uint256 _quantity
    ) public {
        bool verified = MerkleProof.verify(
            _proof,
            roots[_id],
            keccak256(abi.encodePacked(_msgSender(), _id, _quantity))
        );

        require(verified, "Not eligible to redeem");
        require(
            collectionClaims[_id][_msgSender()] == false,
            "Account already claimed for id"
        );

        _mint(_msgSender(), _id, _quantity, "");

        emit RedeemCompleted(_msgSender(), _id, _quantity);
    }

    /// @notice Sets merkle root to a specified token id (need required access control)
    /// @param _id Current id of minted token
    /// @param _root Root of merkle tree for a given collection
    function setRoot(uint256 _id, bytes32 _root) public onlyRole(MINTER_ROLE) {
        roots[_id] = _root;

        emit SetRoot(_id, _root);
    }

    function removeRoot(uint256 _id, bytes32 _root)
        public
        onlyRole(MINTER_ROLE)
    {
        require(roots[_id] == _root, "Root provided is not correct");

        delete roots[_id];
    }

    /// @notice Sets the URI for a token id (need required access control)
    /// @param _id Current id that you're setting the URI to
    /// @param _uri URI that points to the metadata
    function setURI(uint256 _id, string calldata _uri)
        public
        onlyRole(MINTER_ROLE)
    {
        tokenURIs[_id] = _uri;

        emit SetURI(_id, _uri);
    }

    /// @notice Gets the URI for a token id
    /// @param _id Current id you're retriving the URI for
    function uri(uint256 _id) public view override returns (string memory) {
        return tokenURIs[_id];
    }

    /// @notice Assigns minter role to person who message sender
    /// @dev Only admin can set this
    function setMinterRole(address account)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _grantRole(MINTER_ROLE, account);
    }

    /// ==== Overrides ====

    /// @dev Overide function required by Solidity
    /// @param interfaceId interfaceID The interface identifier (specified in ERC-165)
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC1155Upgradeable, AccessControlUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
