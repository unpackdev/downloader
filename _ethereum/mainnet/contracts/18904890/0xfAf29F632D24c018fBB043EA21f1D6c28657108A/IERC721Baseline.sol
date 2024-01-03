// SPDX-License-Identifier: MIT

pragma solidity 0.8.21;

import "./IERC721.sol";
import "./IERC2981.sol";

/**
 * @title IERC721Baseline
 * @custom:version v0.1.0
 * @notice A baseline ERC721 contract implementation that exposes internal methods to a proxy instance.
 */
interface IERC721Baseline is IERC721, IERC2981 {

  /**
   * @notice The version of the implementation contract.
   * @return string the implementation version
   */
  function VERSION() external view returns (string memory);

  /**
   * @dev Indicates an unauthorized operation or unauthorized access attempt.
   */
  error Unauthorized();


  /************************************************
   * Initializer
   ************************************************/

  /**
   * @notice Initializes a proxy contract.
   * @dev This method MUST be called in the proxy constructor via delegatecall
   * to initialize the proxy with a name and symbol for the underlying ERC721.
   *
   * Additionally this method sets the deployer as owner and admin of the proxy.
   *
   * @param name contract name
   * @param symbol contract symbol
   */
  function initialize(string memory name, string memory symbol) external;


  /************************************************
   * Metadata
   ************************************************/

  /**
   * Metadata > ERC-4906 events
   */

  /**
   * @dev This event emits when the metadata of a token is changed.
   * So that the third-party platforms such as NFT market could
   * timely update the images and related attributes of the NFT.
   *
   * @param _tokenId the token ID being updated
   */
  event MetadataUpdate(uint256 _tokenId);

  /**
   * @dev This event emits when the metadata of a range of tokens is changed.
   * So that the third-party platforms such as NFT market could
   * timely update the images and related attributes of the NFTs.
   *
   * @param _fromTokenId the starting token ID
   * @param _toTokenId the ending token ID
   */
  event BatchMetadataUpdate(uint256 _fromTokenId, uint256 _toTokenId);

  /**
   * @notice The total minted supply.
   * @dev The supply is decreased when a token is burned.
   * Generally it is recommended to use a separate counter variable to track the supply available for minting.
   *
   * @return uint256 the existing tokens' supply
   */
  function totalSupply() external view returns (uint256);

  /**
   * Token URI methods.
   *
   * The ERC721Baseline tokenURI implementation allows to define uris in the following order:
   *
   * 1. Token-specific URI by ID.
   * 2. Shared URI.
   * 3. Shared base URI + token ID.
   * 4. Empty string if none of the above was found.
   */

  /**
   * @notice Returns the token URI for a token ID.
   *
   * @param tokenId token ID
   * @return string the token URI for the token ID
   */
  function __tokenURI(uint256 tokenId) external view returns (string memory);

  /**
   * @notice Sets the token URI for a token ID.
   * @dev Emits EIP-4906's `MetadataUpdate` event with the `tokenId`.
   * This method is internal and only the proxy contract can call it.
   *
   * @param tokenId token ID
   * @param tokenURI URI pointing to the metadata
   */
  function __setTokenURI(uint256 tokenId, string calldata tokenURI) external;

  /**
   * @notice Returns the shared URI for the tokens.
   * @dev This method is internal and only the proxy contract can call it.
   *
   * @return string the shared URI
   */
  function __sharedURI() external view returns (string memory);

  /**
   * @notice Sets a shared URI for the tokens.
   * @dev This method doesn't emit the EIP-4906's `BatchMetadataUpdate` event
   * because ERC721Baseline allows to mint any token ID, starting at any index.
   * The proxy should emit `BatchMetadataUpdate`.
   *
   * This method is internal and only the proxy contract can call it.
   *
   * @param sharedURI shared URI for the tokens
   */
  function __setSharedURI(string calldata sharedURI) external;

  /**
   * @notice Returns the base URI for the tokens.
   * @dev When set this URI is prepended to the token ID.
   *
   * @return string the base URI
   */
  function __baseURI() external view returns (string memory);

  /**
   * @notice Sets a contract-wide base URI.
   * @dev This method doesn't emit the EIP-4906 `BatchMetadataUpdate` event
   * because ERC721Baseline allows to mint any token ID, starting at any index.
   * The proxy should emit `BatchMetadataUpdate`.
   *
   * This method is internal and only the proxy contract can call it.
   *
   * @param baseURI shared base URI for the tokens
   */
  function __setBaseURI(string calldata baseURI) external;


  /************************************************
   * Royalties
   ************************************************/

  /**
   * @notice The address of the royalties receiver.
   *
   * @return address the address of the royalties receiver
   */
  function royaltiesReceiver() external view returns (address);

  /**
   * @notice The royalties rate in basis points (100 bps = 1%).
   *
   * @return uint256 the royalties rate
   */
  function royaltiesBps() external view returns (uint256);

  /**
   * @notice Configures royalties receiver and bps for all the tokens.
   * @dev Bps stants for basis points where 100 bps = 1%.
   * The sender must be an admin.
   *
   * @param receiver address for the royalties receiver
   * @param bps (basis points) royalties rate
   */
  function configureRoyalties(address payable receiver, uint16 bps) external;

  /**
   * @notice Configures royalties receiver and bps for all the tokens.
   * @dev Bps stants for basis points where 100 bps = 1%.
   * This method is internal and only the proxy contract can call it.
   *
   * @param receiver address for the royalties receiver
   * @param bps (basis points) royalties rate
   */
  function __configureRoyalties(address payable receiver, uint16 bps) external;


  /************************************************
   * Internal ERC721 methods exposed to the proxy
   ************************************************/

  /**
   * @dev Indicates an invalid attempt to call a method from outside of the proxy.
   */
  error NotProxy();

  /**
   * @dev See {ERC721-_ownerOf}.
   */
  function __ownerOf(uint256 tokenId) external returns (address);

  /**
   * @dev See {ERC721-_update}.
   * This method is internal and only the proxy contract can call it.
   */
  function __update(address to, uint256 tokenId, address auth) external returns (address);

  /**
   * @dev See {ERC721-_mint}.
   * This method is internal and only the proxy contract can call it.
   */
  function __mint(address to, uint256 tokenId) external;

  /**
   * @dev Similar to {ERC721-_mint} but allows to set a dedicated tokenURI for the token.
   * This method is internal and only the proxy contract can call it.
   */
  function __mint(address to, uint256 tokenId, string calldata tokenURI) external;

  /**
   * @dev See {ERC721-_burn}.
   * This method is internal and only the proxy contract can call it.
   */
  function __burn(uint256 tokenId) external;

  /**
   * @dev See {ERC721-_transfer}.
   * This method is internal and only the proxy contract can call it.
   */
  function __transfer(address from, address to, uint256 tokenId) external;

  /**
   * @notice Allows to enable or disable a `_beforeTokenTransfer` hook method defined in the proxy contract.
   * @dev This method is internal and only the proxy contract can call it.
   *
   * When enabled, the proxy's `_beforeTokenTransfer` hook method is invoked prior to a transfer.
   *
   * The proxy's `_beforeTokenTransfer` method is called with the following params:
   *
   * - address the transaction's _msgSender()
   * - address from
   * - address to
   * - uint256 tokenId
   *
   * This method is internal and only the proxy contract can call it.
   */
  function __setBeforeTokenTransferHookEnabled(bool enabled) external;

  /**
   * @dev See {ERC721-_checkOnERC721Received}.
   *
   * NOTE: this method accepts an additional first parameter that is the original transaction's `msg.sender`.
   */
  function __checkOnERC721Received(address sender, address from, address to, uint256 tokenId, bytes memory data) external;

  /**
   * @dev See {ERC721-_isAuthorized}.
   */
  function __isAuthorized(address owner, address spender, uint256 tokenId) external view returns (bool);

  /**
   * @dev See {ERC721-_approve}.
   * This method is internal and only the proxy contract can call it.
   */
  function __approve(address to, uint256 tokenId, address auth, bool emitEvent) external;

  /**
   * @dev See {ERC721-_setApprovalForAll}.
   * This method is internal and only the proxy contract can call it.
   */
  function __setApprovalForAll(address owner, address operator, bool approved) external;


  /************************************************
   * Access control
   ************************************************/

  /**
   * Implements a multi-admin system and a minimal Ownable-compatible API.
   */

  /**
   * Access control > multi-admin system
   */

  /**
   * @notice Checks if an address is the contract owner or an admin.
   *
   * @param addr address to check
   * @return bool whether the address is an admin or not
   */
  function isAdmin(address addr) external view returns (bool);

  /**
   * @dev Emits when an admin is added or removed.
   *
   * @param addr address that is being added or removed as an admin
   * @param add boolean indicating whether the address was grented or revoked admin rights
   */
  event AdminSet(address indexed addr, bool indexed add);

  /**
   * @notice Allows to add or remove an admin.
   * Can only be called by an admin.
   *
   * @param addr address to add or remove
   * @param add boolean indicating whether the address should be granted or revoked rights
   */
  function setAdmin(address addr, bool add) external;

  /**
   * @notice Checks whether an address is an admin and reverts with an `Unauthorized` error if not.
   * @dev Call `requireAdmin` in proxies to implement admin-only public methods.
   *
   * @param addr the address to check
   */
  function requireAdmin(address addr) external view;

  /**
   * @notice Allows to add or remove an admin.
   * @dev This method is internal and only the proxy contract can call it.
   *
   * @param addr address to add or remove
   * @param add boolean indicating whether the address should be granted or revoked rights
   */
  function __setAdmin(address addr, bool add) external;

  /**
   * Access control > Ownable-compatible API.
   */

  /**
   * @notice Returns the address of the contract owner.
   *
   * @return address of the contract owner
   */
  function owner() external view returns (address);

  /**
   * @dev Emits when the contract ownership is transferred.
   *
   * @param previousOwner old owner address
   * @param newOwner new owner address
   */
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
   * @notice Transfers ownership of the contract to a new account.
   * Can only be called by an admin.
   *
   * @param newOwner new owner address
   */
  function transferOwnership(address newOwner) external;

  /**
   * @notice Transfers ownership of the contract to a new account.
   * @dev This method is internal and only the proxy contract can call it.
   *
   * @param newOwner new owner address
   */
  function __transferOwnership(address newOwner) external;


  /************************************************
   * Utils
   ************************************************/

  /**
   * @dev Indicates an invalid signature.
   */
  error InvalidSignature();

  /**
   * @notice Recovers the signer's address from a message digest `hash`, and the `signature`.
   *
   * @param hash the message digest that was signed
   * @param signature the signature for hash
   * @return result address the recovered address
   */
  function recover(bytes32 hash, bytes memory signature) external view returns (address result);

  /**
   * @notice Recovers the signer's address from a message digest `hash`, and the `signature`.
   * @dev In this method the signature comes from calldata.
   *
   * @param hash the message digest that was signed
   * @param signature the signature for hash
   * @return result address the recovered address
   */
  function recoverCalldata(bytes32 hash, bytes calldata signature) external view returns (address result);

  /**
   * @notice Converts a uint256 to string
   *
   * @param value the uint256 to convert
   * @return string ASCII string decimal representation of `value`
   */
  function toString(uint256 value) external pure returns (string memory);

}
