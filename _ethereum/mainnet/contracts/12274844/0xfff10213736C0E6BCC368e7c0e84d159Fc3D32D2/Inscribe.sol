pragma solidity 0.8.0;

// SPDX-License-Identifier: MIT

import "./InscribeInterface.sol";
import "./InscribeMetaDataInterface.sol";
import "./IERC721.sol";
import "./Strings.sol";
import "./ECDSA.sol";


contract InscribeMetadata is InscribeMetaDataInterface {
    
    struct BaseURI {
        string baseUri;
        address owner;
    }
    
    // Mapping from baseUriId to a BaseURI struct
    mapping (uint256 => BaseURI) internal _baseUriMapping;
        
    /**
     * @dev The latest baseUriId. This ID increases by 1 every time a new 
     * base URI is created.
     */ 
    uint256 internal latestBaseUriId;

    /**
     * @dev See {InscribeMetaDataInterface-addBaseURI}.
     */
    function addBaseURI(string memory baseUri) public override {
        emit BaseURIAdded(latestBaseUriId, baseUri);
        _baseUriMapping[latestBaseUriId] = BaseURI(baseUri, msg.sender);
        latestBaseUriId++;
    }
    
    /**
     * @dev See {InscribeMetaDataInterface-migrateBaseURI}.
     */
    function migrateBaseURI(uint256 baseUriId, string memory baseUri) external override {
        BaseURI memory uri = _baseUriMapping[baseUriId];

        require(_baseURIExists(uri), "Base URI does not exist");
        require(uri.owner == msg.sender, "Only owner of the URI may migrate the URI");
        
        emit BaseURIModified(baseUriId, baseUri);
        _baseUriMapping[baseUriId] = BaseURI(baseUri, msg.sender);
    }

    /**
     * @dev See {InscribeMetaDataInterface-getBaseURI}.
     */
    function getBaseURI(uint256 baseUriId) public view override returns (string memory baseURI) {
        BaseURI memory uri = _baseUriMapping[baseUriId];
        require(_baseURIExists(uri), "Base URI does not exist");
        return uri.baseUri;
    }
    
    /**
     * @dev Verifies if the base URI at the specified Id exists
     */ 
    function _baseURIExists(BaseURI memory uri) internal pure returns (bool) {
        return uri.owner != address(0);
    }
}


contract Inscribe is InscribeInterface, InscribeMetadata {
    using Strings for uint256;
    using ECDSA for bytes32;
        
    // --- Storage of inscriptions ---

    // In order to save storage, we emit the contentHash instead of storing it on chain
    // Thus frontends must verify that the content hash that was emitted must match 

    // Mapping from inscription ID to the address of the inscriber
    mapping (uint256 => address) private _inscribers;

    // Mapping from inscription Id to a hash of the nftAddress and tokenId
    mapping (uint256 => bytes32) private _locationHashes;

    // Mapping from inscription ID to base URI IDs
    // Inscriptions managed by an operator use base uri
    // URIs are of the form {baseUrl}{inscriptionId}
    mapping (uint256 => uint256) private _baseURIIds;

    // Mapping from inscription ID to inscriptionURI
    mapping (uint256 => string) private _inscriptionURIs;

    // mapping from an inscriber address to a mapping of location hash to nonces
    mapping (address => mapping (bytes32 => uint256)) private _nonces;

    // --- Approvals ---

    // Mapping from an NFT address to a mapping of a token ID to an approved address
    mapping (address => mapping (uint256 => address)) private _inscriptionApprovals;

    // Mapping from owner to operator approvals
    mapping (address => mapping (address => bool)) private _operatorApprovals;

    bytes32 public immutable domainSeparator;

    // Used for calculationg inscription Ids when adding without a sig
    uint256 latestInscriptionId;

    //keccak256("AddInscription(address nftAddress,uint256 tokenId,bytes32 contentHash,uint256 nonce)");
    bytes32 public constant ADD_INSCRIPTION_TYPEHASH = 0x6b7aae47ef1cd82bf33fbe47ef7d5d948c32a966662d56eb728bd4a5ed1082ea;

    constructor () {
        latestBaseUriId = 1;
        latestInscriptionId = 1;

        uint256 chainID;

        assembly {
            chainID := chainid()
        }

        domainSeparator = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                keccak256(bytes("Inscribe")),
                keccak256(bytes("1")),
                chainID,
                address(this)
            )
        );
    }

    /**
     * @dev See {InscribeInterface-getInscriber}.
     */
    function getInscriber(uint256 inscriptionId) external view override returns (address) {
        address inscriber = _inscribers[inscriptionId];
        require(inscriber != address(0), "Inscription does not exist");
        return inscriber;
    }

    /**
     * @dev See {InscribeInterface-verifyInscription}.
     */
    function verifyInscription(uint256 inscriptionId, address nftAddress, uint256 tokenId) public view override returns (bool) {
        bytes32 locationHash = _locationHashes[inscriptionId];
        return locationHash == keccak256(abi.encodePacked(nftAddress, tokenId));
    }

    /**
     * @dev See {InscribeInterface-getInscriptionURI}.
     */
    function getNonce(address inscriber, address nftAddress, uint256 tokenId) external view override returns (uint256) {
        bytes32 locationHash = keccak256(abi.encodePacked(nftAddress, tokenId));
        return _nonces[inscriber][locationHash];
    }

    /**
     * @dev See {InscribeInterface-getInscriptionURI}.
     */
    function getInscriptionURI(uint256 inscriptionId) external view override returns (string memory inscriptionURI) {
        require(_inscriptionExists(inscriptionId), "Inscription does not exist");
                
        uint256 baseUriId = _baseURIIds[inscriptionId];

        if (baseUriId == 0) {
            return _inscriptionURIs[inscriptionId];
        } else {
            BaseURI memory uri = _baseUriMapping[baseUriId];
            require(_baseURIExists(uri), "Base URI does not exist");
            return string(abi.encodePacked(uri.baseUri, inscriptionId.toString()));
        }
    }

    /**
     * @dev See {InscribeApprovalInterface-approve}.
     */
    function approve(address to, address nftAddress, uint256 tokenId) public override {
        address owner = _ownerOf(nftAddress, tokenId);
        require(owner != address(0), "Nonexistent token ID");

        require(to != owner, "Cannot approve the 'to' address as it belongs to the nft owner");

        require(msg.sender == owner || isApprovedForAll(owner, msg.sender), "Approve caller is not owner nor approved for all");

        _approve(to, nftAddress, tokenId);
    }

    /**
     * @dev See {InscribeApprovalInterface-getApproved}.
     */
    function getApproved(address nftAddress, uint256 tokenId) public view override returns (address) {
        return _inscriptionApprovals[nftAddress][tokenId];
    }

    /**
     * @dev See {InscribeApprovalInterface-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) external override {
        require(operator != msg.sender, "Operator cannot be the same as the caller");

        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);    
    }

    /**
     * @dev See {InscribeApprovalInterface-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {InscribeApprovalInterface-addInscriptionWithNoSig}.
     */
    function addInscriptionWithNoSig(
        address nftAddress,
        uint256 tokenId,
        bytes32 contentHash,
        uint256 baseUriId
    ) external override {
        require(nftAddress != address(0));
        require(baseUriId != 0);

        require(_isApprovedOrOwner(msg.sender, nftAddress, tokenId));
        
        BaseURI memory uri = _baseUriMapping[baseUriId];
        require(_baseURIExists(uri), "Base URI does not exist");
        _baseURIIds[latestInscriptionId] = baseUriId;

        bytes32 locationHash = keccak256(abi.encodePacked(nftAddress, tokenId));

        _addInscription(nftAddress, tokenId, msg.sender, contentHash, latestInscriptionId, locationHash);

        latestInscriptionId++;
    }
    
    /**
     * @dev See {InscribeInterface-addInscription}.
     */
    function addInscriptionWithBaseUriId(
        address nftAddress,
        uint256 tokenId,
        address inscriber,
        bytes32 contentHash,
        uint256 baseUriId,
        uint256 nonce,
        bytes calldata sig
    ) external override {
        require(inscriber != address(0));
        require(nftAddress != address(0));

        bytes32 locationHash = keccak256(abi.encodePacked(nftAddress, tokenId));
        require(_nonces[inscriber][locationHash] == nonce, "Nonce mismatch, sign again with the nonce from `getNonce`");

        bytes32 digest = _generateAddInscriptionHash(nftAddress, tokenId, contentHash, nonce);

        // Verifies the signature
        require(_recoverSigner(digest, sig) == inscriber, "Recovered address does not match inscriber");

        require(_isApprovedOrOwner(msg.sender, nftAddress, tokenId), "NFT does not belong to msg sender");

        uint256 inscriptionId = latestInscriptionId;

        // Add metadata
        BaseURI memory uri = _baseUriMapping[baseUriId];
        require(_baseURIExists(uri), "Base URI does not exist");
        _baseURIIds[inscriptionId] = baseUriId;

        // Update nonce
        _nonces[inscriber][locationHash]++;

        // Store inscription
        _addInscription(nftAddress, tokenId, inscriber, contentHash, inscriptionId, locationHash); 

        latestInscriptionId++;
    }

    /**
     * @dev See {InscribeInterface-addInscription}.
     */
    function addInscriptionWithInscriptionUri(
        address nftAddress,
        uint256 tokenId,
        address inscriber,
        bytes32 contentHash,
        string calldata inscriptionURI,
        uint256 nonce,
        bytes calldata sig
    ) external override {
        require(inscriber != address(0));
        require(nftAddress != address(0));

        bytes32 locationHash = keccak256(abi.encodePacked(nftAddress, tokenId));
        require(_nonces[inscriber][locationHash] == nonce, "Nonce mismatch, sign again with the nonce from `getNonce`");

        bytes32 digest = _generateAddInscriptionHash(nftAddress, tokenId, contentHash, nonce);

        // Verifies the signature
        require(_recoverSigner(digest, sig) == inscriber, "Recovered address does not match inscriber");

        require(_isApprovedOrOwner(msg.sender, nftAddress, tokenId), "NFT does not belong to msg sender");

        // Add metadata 
        uint256 inscriptionId = latestInscriptionId;

        _baseURIIds[inscriptionId] = 0;
        _inscriptionURIs[inscriptionId] = inscriptionURI;

        // Update nonce
        _nonces[inscriber][locationHash]++;

        _addInscription(nftAddress, tokenId, inscriber, contentHash, inscriptionId, locationHash); 
        
        latestInscriptionId++;
    }

    /**
     * @dev See {InscribeInterface-removeInscription}.
     */
    function removeInscription(uint256 inscriptionId, address nftAddress, uint256 tokenId) external override {
        require(_inscriptionExists(inscriptionId), "Inscription does not exist at this ID");

        require(verifyInscription(inscriptionId, nftAddress, tokenId), "Verifies nftAddress and tokenId are legitimate");

        // Verifies that the msg.sender has permissions to remove an inscription
        require(_isApprovedOrOwner(msg.sender, nftAddress, tokenId), "Caller does not own inscription or is not approved");

        _removeInscription(inscriptionId, nftAddress, tokenId);
    }

    // -- Migrating URIs

    // Migrations are necessary if you would like an inscription operator to host your content hash
    // 
    function migrateURI(
        uint256 inscriptionId, 
        uint256 baseUriId, 
        address nftAddress, 
        uint256 tokenId
    ) external override {
        require(_inscriptionExists(inscriptionId), "Inscription does not exist at this ID");

        require(verifyInscription(inscriptionId, nftAddress, tokenId), "Verifies nftAddress and tokenId are legitimate");

        require(_isApprovedOrOwner(msg.sender, nftAddress, tokenId), "Caller does not own inscription or is not approved");

        _baseURIIds[inscriptionId] = baseUriId;
        delete _inscriptionURIs[inscriptionId];
    }

    function migrateURI(
        uint256 inscriptionId, 
        string calldata inscriptionURI, 
        address nftAddress, 
        uint256 tokenId
    ) external override{
        require(_inscriptionExists(inscriptionId), "Inscription does not exist at this ID");

        require(verifyInscription(inscriptionId, nftAddress, tokenId), "Verifies nftAddress and tokenId are legitimate");

        require(_isApprovedOrOwner(msg.sender, nftAddress, tokenId), "Caller does not own inscription or is not approved");

        _baseURIIds[inscriptionId] = 0;
        _inscriptionURIs[inscriptionId] = inscriptionURI;
    }

    /**
     * @dev Returns whether the `inscriber` is allowed to add or remove an inscription to `tokenId` at `nftAddress`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address inscriber, address nftAddress, uint256 tokenId) private view returns (bool) {
        address owner = _ownerOf(nftAddress, tokenId);
        require(owner != address(0), "Nonexistent token ID");
        return (inscriber == owner || getApproved(nftAddress, tokenId) == inscriber || isApprovedForAll(owner, inscriber));
    }
    
    /**
     * @dev Adds an approval on chain
     */
    function _approve(address to, address nftAddress, uint256 tokenId) internal {
        _inscriptionApprovals[nftAddress][tokenId] = to;
        emit Approval(_ownerOf(nftAddress, tokenId), to, nftAddress, tokenId);
    }
    
    /**
     * @dev Returns the owner of `tokenId` at `nftAddress`
     */
    function _ownerOf(address nftAddress, uint256 tokenId) internal view returns (address){
        IERC721 nftContractInterface = IERC721(nftAddress);
        return nftContractInterface.ownerOf(tokenId);
    }
    
    /**
     * @dev Removes an inscription on-chain after all requirements were met
     */
    function _removeInscription(uint256 inscriptionId, address nftAddress, uint256 tokenId) private {
        // Clear approvals from the previous inscriber
        _approve(address(0), nftAddress, tokenId);
        
        // Remove Inscription
        address inscriber = _inscribers[inscriptionId];

        delete _inscribers[inscriptionId];
        delete _locationHashes[inscriptionId];
        delete _inscriptionURIs[inscriptionId];

        emit InscriptionRemoved(
            inscriptionId, 
            nftAddress,
            tokenId,
            inscriber);
    }
    
    /**
    * @dev Adds an inscription on-chain with optional URI after all requirements were met
    */
    function _addInscription(
        address nftAddress,
        uint256 tokenId,
        address inscriber,
        bytes32 contentHash,
        uint256 inscriptionId,
        bytes32 locationHash
    ) private {

        _inscribers[inscriptionId] = inscriber;
        _locationHashes[inscriptionId] = locationHash;

        emit InscriptionAdded(
            inscriptionId, 
            nftAddress, 
            tokenId, 
            inscriber, 
            contentHash
        );
    }
    
    /**
     * @dev Verifies if an inscription at `inscriptionID` exists
     */ 
    function _inscriptionExists(uint256 inscriptionId) private view returns (bool) {
        return _inscribers[inscriptionId] != address(0);
    }

    /**
     * @dev Generates the EIP712 hash that was signed
     */ 
    function _generateAddInscriptionHash(
        address nftAddress,
        uint256 tokenId,
        bytes32 contentHash,
        uint256 nonce
    ) private view returns (bytes32) {

        // Recreate signed message 
        return keccak256(
            abi.encodePacked(
                "\x19\x01",
                domainSeparator,
                keccak256(
                    abi.encode(
                        ADD_INSCRIPTION_TYPEHASH,
                        nftAddress,
                        tokenId,
                        contentHash,
                        nonce
                    )
                )
            )
        );
    }
    
    function _recoverSigner(bytes32 _hash, bytes memory _sig) private pure returns (address) {
        address signer = ECDSA.recover(_hash, _sig);
        require(signer != address(0));
        return signer;
    }
}