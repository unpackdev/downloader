// TODO FIXME
// - view scripts inline
// - Mass-minting
// - Also make it ERC1155???
// ---

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./RoleBasedAccessControlLib.sol";
import "./ERC721Lib.sol";
import "./IERC2981.sol";
import "./IERC2981Candidate.sol";
import "./IERC721Receiver.sol";
import "./Counters.sol";
import "./IERC20.sol";

/**
 * @dev {ERC721} token, including:
 *
 *  - a minter role that allows for token minting (creation)
 *  - a pauser role that allows to stop all token transfers
 *  - token ID and URI autogeneration
 *
 * This contract uses {AccessControl} to lock permissioned functions using the
 * different roles - head to its documentation for details.
 *
 * The account that deploys the contract will be granted the minter and pauser
 * roles, as well as the default admin role, which will let it grant both minter
 * and pauser roles to other accounts.
 *
 * This contract is based on the excellent work and contracts of Open Zeppelin.
 *
 */
contract TideweighUniques721 {
    using ERC721Lib for ERC721Lib.ERC721Storage;
    using RoleBasedAccessControlLib for RoleBasedAccessControlLib.RoleBasedAccessControlStorage;
    using Counters for Counters.Counter;

    // Shadow events defined in the libraries, need to be included here again to make it into the ABI
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event Mint(address indexed to, uint256 indexed tokenId);
    event Paused(address account);
    event Unpaused(address account);
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    event Received(address operator, address from, uint256 tokenId, bytes data, uint256 gas);

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant INFINITIZER_ROLE = keccak256("INFINITIZER_ROLE");

    address tideweigh; // Contract owner
    uint24 royalty;    // Royalty expected by the artist on secondary transfers (IERC2981)

    string public contractURI; // OpenSea contract-level metadata uri

    Counters.Counter private _tokenIdTracker; // Token ID counter

    mapping(uint256 => string) tokenIdToIpfsCID;                 // Each minted token can be infinitized to IPFS

    ERC721Lib.ERC721Storage token; // ERC721 token base
    RoleBasedAccessControlLib.RoleBasedAccessControlStorage rbac; // Role based access control

    constructor(string memory _name, string memory _symbol, string memory baseTokenURI, address _proxyRegistryAddress) {
        token.init(_name, _symbol);
        token._baseURI = baseTokenURI;

        tideweigh = msg.sender;
        emit OwnershipTransferred(address(0), tideweigh);

        // Grant owner a reasonable set of roles by default
        rbac._setupRole(RoleBasedAccessControlLib.DEFAULT_ADMIN_ROLE, msg.sender);
        rbac._setupRole(MINTER_ROLE, msg.sender);
        rbac._setupRole(PAUSER_ROLE, msg.sender);
        rbac._setupRole(INFINITIZER_ROLE, msg.sender);

        token.proxyRegistryAddress = _proxyRegistryAddress;

    }

    // Access control primitives

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() external view returns (address) {
        return tideweigh;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public {
        require(tideweigh == msg.sender && newOwner != address(0), "Ownership transfer impossible");
        emit OwnershipTransferred(tideweigh, newOwner);
        tideweigh = newOwner;
    }

    function onlyAdmin() private view {
        require(rbac.hasRole(RoleBasedAccessControlLib.DEFAULT_ADMIN_ROLE, msg.sender), "Must have admin role");
    }

    function onlyPauser() private view {
        require(rbac.hasRole(PAUSER_ROLE, msg.sender), "Must have pauser role");
    }

    //
    // ERC165 interface implementation
    //

    function supportsInterface(bytes4 interfaceId) external pure returns (bool) {
        return interfaceId == type(IERC165).interfaceId
            || interfaceId == type(IERC721Receiver).interfaceId
            || ERC721Lib.supportsInterface(interfaceId)
            || interfaceId == type(IERC2981).interfaceId
            || interfaceId == type(IERC2981Candidate).interfaceId
            || RoleBasedAccessControlLib.supportsInterface(interfaceId);
    }

    //
    // ERC721 interface implementation
    //

    function balanceOf(address _owner) external view returns (uint256 balance) { 
        return token.balanceOf(_owner); 
    }

    function ownerOf(uint256 tokenId) external view returns (address _owner) { 
        return token.ownerOf(tokenId); 
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) external { 
        token.safeTransferFrom(from, to, tokenId); 
    }

    function transferFrom(address from, address to, uint256 tokenId) external { 
        token.safeTransferFrom(from, to, tokenId); 
    }

    function approve(address to, uint256 tokenId) external { 
        token.approve(to, tokenId); 
    }

    function getApproved(uint256 tokenId) external view returns (address operator) { 
        return token.getApproved(tokenId); 
    }

    function setApprovalForAll(address operator, bool _approved) external { 
        token.setApprovalForAll(operator, _approved); 
    }

    function isApprovedForAll(address _owner, address operator) external view returns (bool) { 
        return token.isApprovedForAll(_owner, operator); 
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external { 
        token.safeTransferFrom(from, to, tokenId, data); 
    }

    //
    // ERC721Enumerable interface implementation
    //

    function totalSupply() external view returns (uint256) {
        return token.totalSupply();
    }

    function tokenOfOwnerByIndex(address _owner, uint256 index) external view returns (uint256 tokenId) {
        return token.tokenOfOwnerByIndex(_owner, index);
    }

    function tokenByIndex(uint256 index) external view returns (uint256) {
        return token.tokenByIndex(index);
    }

    //
    // ERC721Metadata interface implementation
    //

    function name() external view returns (string memory) {
        return token.name();
    }

    function symbol() external view returns (string memory) {
        return token.symbol();
    }

    function tokenURI(uint256 tokenId) external view returns (string memory) {
        require(token._exists(tokenId), "URI query for nonexistent token");

        return bytes(tokenIdToIpfsCID[tokenId]).length > 0 
            ? string(abi.encodePacked("ipfs://", tokenIdToIpfsCID[tokenId]))
            : token.tokenURI(tokenId);
    }

    // Allow updates of base URI
    function setBaseURI(string memory baseTokenURI) external {
        onlyAdmin();
        return token.setBaseURI(baseTokenURI);
    }

    function baseURI() external view returns (string memory) {
        return token._baseURI;
    }

    /**
     * @dev Infinitize the token to IPFS
     *
     * Set the token's CID. Null/zero length byte array is allowed to remove the CID.
     *
     */
    function setIpfsCID(uint256 tokenId, string calldata ipfsCID) external {
        require(rbac.hasRole(INFINITIZER_ROLE, msg.sender), "Must have infinitizer role");
        require(token._exists(tokenId), "URI query for nonexistent token");

        tokenIdToIpfsCID[tokenId] = ipfsCID;
    }

    //
    // Pausable interface implementation
    //

    function paused() external view virtual returns (bool) {
        return token.paused();
    }

    function pause() external {
        onlyPauser();
        token._pause();
    }

    function unpause() external {
        onlyPauser();
        token._unpause();
    }

    //
    // Role Based Access Control interface implementation
    //

    function hasRole(bytes32 role, address account) external view returns (bool) {
        return rbac.hasRole(role, account);
    }

    function getRoleAdmin(bytes32 role) external view returns (bytes32) {
        return rbac.getRoleAdmin(role);
    }

    function grantRole(bytes32 role, address account) external {
        return rbac.grantRole(role, account);
    }

    function revokeRole(bytes32 role, address account) external {
        return rbac.revokeRole(role, account);
    }

    function renounceRole(bytes32 role, address account) external {
        return rbac.renounceRole(role, account);
    }

    function getRoleMember(bytes32 role, uint256 index) external view returns (address) {
        return rbac.getRoleMember(role, index);
    }

    function getRoleMemberCount(bytes32 role) external view returns (uint256) {
        return rbac.getRoleMemberCount(role);
    }

    //
    // OpenSea registry functions
    //

    /* @dev Update the OpenSea proxy registry address
     *
     * Zero address is allowed, and disables the whitelisting
     *
     */
    function setProxyRegistryAddress(address _proxyRegistryAddress) external {
        onlyAdmin();
        token.proxyRegistryAddress = _proxyRegistryAddress;
    }

    /* @dev Retrieve the current OpenSea proxy registry address
     *
     * Zero indicates that OpenSea whitelisting is disabled
     *
     */
    function getProxyRegistryAddress() external view returns (address) {
        return token.proxyRegistryAddress;
    }

    /**
     * @dev Creates a new token for `to`. Its token ID will be automatically
     * assigned (and available on the emitted {IERC721-Transfer} event), and the token
     * URI autogenerated based on the base URI passed at construction.
     *
     * See {ERC721-_mint}.
     *
     * Requirements:
     *
     * - the caller must have the `MINTER_ROLE`.
     */
    function mint(address to, bytes memory _data) public virtual {
        require(rbac.hasRole(MINTER_ROLE, msg.sender), "Must have minter role");
        // We cannot just use balanceOf to create the new tokenId because tokens
        // can be burned (destroyed), so we need a separate counter.
        token._safeMint(to, _tokenIdTracker.current(), _data);
        _tokenIdTracker.increment();
    }
    
    /**
     * @dev Creates a new token for `to`. Its token ID will be automatically
     * assigned (and available on the emitted {IERC721-Transfer} event), and the token
     * URI autogenerated based on the base URI passed at construction.
     *
     * See {ERC721-_mint}.
     *
     * Requirements:
     *
     * - the caller must have the `MINTER_ROLE`.
     */
    function mint(address to) public virtual {
        mint(to, "");
    }
    
    /**
     * @dev Burns `tokenId`. See {ERC721-_burn}.
     *
     * Requirements:
     *
     * - The caller must own `tokenId` or be an approved operator.
     */
    function burn(uint256 tokenId) public virtual {
        require(token._isApprovedOrOwner(msg.sender, tokenId), "Caller not owner nor approved");
        token._burn(tokenId);
    }

    /**
     * @dev set contract URI for OpenSea
     */
    function setContractURI(string calldata _contractURI) external {
        onlyAdmin();
        contractURI = _contractURI;
    }

    //
    // ERC2981 royalties interface implementation
    //

    /**
     * @dev See {IERC2981-royaltyInfo}.
     */
    function royaltyInfo(uint256 /* _tokenId */, uint256 _value, bytes calldata /* _data */) external view returns (address receiver, uint256 royaltyAmount, bytes memory royaltyPaymentData) {
        return (tideweigh, royalty * _value / 100, "");
    }

    function royaltyInfo(uint256 /* _tokenId */, uint256 _value) external view returns (address receiver, uint256 royaltyAmount) {
        return (tideweigh, royalty * _value / 100);
    }

    /**
     * @dev Update expected royalty
     */
    function setRoyaltyInfo(uint24 amount) external {
        onlyAdmin();
        royalty = amount;
    }

    //
    // ERC721Receiver interface implementation
    //

    /**
     * @dev ERC721 received event handler
     */
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4) {
        // Acknowledge receipt of token
        emit Received(operator, from, tokenId, data, gasleft()); 
        return IERC721Receiver.onERC721Received.selector;
    }

    /**
     * @dev Manually recover all sorts of tokens sent to this contract 
     *
     * Supports various recovery attempt types
     */
    function recoverReceivedTokens(uint256 _recoveryOperation, address _contractAddress, address _from, address _to, uint256 _tokenIdOrValue, bytes calldata _data) external returns (bool) {
        onlyAdmin();

        if(_recoveryOperation <= 2) {
            IERC721 erc721Contract = IERC721(_contractAddress);
            if(_recoveryOperation == 0) {
                erc721Contract.safeTransferFrom(_from, _to, _tokenIdOrValue, _data);
            } else if(_recoveryOperation == 1) {
                erc721Contract.safeTransferFrom(_from, _to, _tokenIdOrValue);
            } else {
                // _recoveryOperation == 2
                erc721Contract.transferFrom(_from, _to, _tokenIdOrValue);
            } 
        } else if(_recoveryOperation <= 4) {
            IERC20 erc20Contract = IERC20(_contractAddress);
            if(_recoveryOperation == 3) {
                return erc20Contract.transfer(_to, _tokenIdOrValue);
            } else {
                // _recoveryOperation == 4
                return erc20Contract.approve(_to, _tokenIdOrValue);
            } 
        } else if(_recoveryOperation == 5) {
            payable(msg.sender).transfer(_tokenIdOrValue);
        } else {
            revert('Invalid recovery operation');
        }
        return true;
    }

}
